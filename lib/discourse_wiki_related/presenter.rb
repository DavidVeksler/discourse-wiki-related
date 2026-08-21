# frozen_string_literal: true

require "digest"
require "json"
require "uri"

module DiscourseWikiRelated
  class Presenter
    EXPECTED_SITE_BY_HOST = {
      "wiki.objectivismonline.com" => "objectivism-online",
      "wiki.freecapitalists.org" => "mises-community"
    }.freeze
    MAX_LINKS = 3
    WARNING_TTL = 5.minutes.to_i

    def initialize(topic, stored_value)
      @topic = topic
      @stored_value = stored_value
    end

    def card
      return nil if !SiteSetting.wiki_related_enabled || !eligible_topic?

      base = validated_base_uri
      return nil if !base

      row = parse_row
      return nil if !row

      expected_site = EXPECTED_SITE_BY_HOST[base.host]
      return reject("wrong site key") if row["site_key"] != expected_site
      if !row["mapping_version"].is_a?(String) ||
           !row["mapping_version"].match?(/\Av[1-9][0-9]*\z/)
        return reject("invalid mapping version")
      end

      raw_links = row["links"]
      if !raw_links.is_a?(Array) || raw_links.empty?
        return reject("links must be a non-empty array")
      end

      limit = [[SiteSetting.wiki_related_max_links.to_i, 1].max, MAX_LINKS].min
      links = raw_links.first(limit).map { |link| present_link(link, base) }
      return nil if links.any?(&:nil?)

      { heading: SiteSetting.wiki_related_heading.to_s, links: links }
    rescue StandardError => error
      reject("unexpected #{error.class}")
    end

    private

    def eligible_topic?
      @topic && @topic.archetype == Archetype.default &&
        @topic.deleted_at.nil? && @topic.visible? && !@topic.private_message? &&
        !@topic.category&.read_restricted?
    end

    def validated_base_uri
      uri = URI.parse(SiteSetting.wiki_related_wiki_base_url.to_s)
      expected_site = EXPECTED_SITE_BY_HOST[uri.host&.downcase]
      if uri.scheme != "https" || !expected_site
        return reject("unsupported wiki origin")
      end
      if uri.userinfo || uri.port != 443 || !["", "/"].include?(uri.path) ||
           uri.query || uri.fragment
        return reject("wiki base URL must be an origin")
      end

      uri
    rescue URI::InvalidURIError
      reject("invalid wiki base URL")
    end

    def parse_row
      value = @stored_value
      value = JSON.parse(value) if value.is_a?(String)
      return reject("stored value is not an object") if !value.is_a?(Hash)

      value.deep_stringify_keys
    rescue JSON::ParserError
      reject("stored value is not JSON")
    end

    def present_link(raw_link, base)
      return reject("link is not an object") if !raw_link.is_a?(Hash)

      link = raw_link.deep_stringify_keys
      title = link["title"]
      path = link["path"]
      score = link["score"]
      if !title.is_a?(String) || title.blank? || title.length > 500
        return reject("invalid link title")
      end
      if !score.is_a?(Numeric) || !score.finite?
        return reject("invalid link score")
      end
      return reject("invalid relative path") if !valid_relative_path?(path)

      uri = base.dup
      uri.path = path
      uri.query = URI.encode_www_form("utm_source" => "forum-crosslink")
      if uri.scheme != "https" || uri.host != base.host
        return reject("constructed URL escaped wiki origin")
      end

      { title: title, url: uri.to_s }
    rescue URI::InvalidURIError
      reject("relative path is not a URI")
    end

    def valid_relative_path?(path)
      if !path.is_a?(String) || path.blank? || !path.start_with?("/")
        return false
      end
      if path.start_with?("//") || path.include?("\\") ||
           path.match?(/%(?![0-9A-Fa-f]{2})/)
        return false
      end

      parsed = URI.parse(path)
      if parsed.absolute? || parsed.host || parsed.query || parsed.fragment
        return false
      end

      decoded_segments =
        parsed
          .path
          .split("/")
          .map { |segment| URI.decode_www_form_component(segment) }
      decoded_segments.none? { |segment| segment == "." || segment == ".." }
    rescue URI::InvalidURIError, ArgumentError
      false
    end

    def reject(reason)
      topic_id = @topic&.id || "unknown"
      key =
        "discourse-wiki-related-warning:#{Digest::SHA256.hexdigest("#{topic_id}:#{reason}")[0, 20]}"
      if Discourse.redis.set(key, "1", nx: true, ex: WARNING_TTL)
        Rails.logger.warn(
          "[discourse-wiki-related] topic #{topic_id}: #{reason}; card suppressed"
        )
      end
      nil
    rescue StandardError
      nil
    end
  end
end
