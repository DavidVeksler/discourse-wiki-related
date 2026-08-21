# frozen_string_literal: true

# name: discourse-wiki-related
# about: Shows validated related-wiki links on topic pages and crawler HTML.
# version: 0.2.0
# authors: David Veksler
# url: https://github.com/DavidVeksler/discourse-wiki-related
# required_version: 3.3.0

enabled_site_setting :wiki_related_enabled

register_asset "stylesheets/common/wiki-related.scss"

after_initialize do
  module ::DiscourseWikiRelated
    PLUGIN_NAME = "discourse-wiki-related"
    CUSTOM_FIELD = "wiki_related"
  end

  require_relative "lib/discourse_wiki_related/presenter"

  register_topic_custom_field_type DiscourseWikiRelated::CUSTOM_FIELD, :json

  add_to_serializer(
    :topic_view,
    :wiki_related,
    include_condition: -> { SiteSetting.wiki_related_enabled }
  ) do
    DiscourseWikiRelated::Presenter.new(
      object.topic,
      object.topic.custom_fields[DiscourseWikiRelated::CUSTOM_FIELD]
    ).card
  end

  register_html_builder("server:topic-show-after-posts-crawler") do |controller|
    if !controller.instance_of?(TopicsController) ||
         !SiteSetting.wiki_related_enabled
      next ""
    end

    topic_view = controller.instance_variable_get(:@topic_view)
    topic = topic_view&.topic
    next "" if !topic

    card =
      DiscourseWikiRelated::Presenter.new(
        topic,
        topic.custom_fields[DiscourseWikiRelated::CUSTOM_FIELD]
      ).card
    next "" if !card

    helpers = ApplicationController.helpers
    items =
      card[:links].map do |link|
        helpers.content_tag(:li, helpers.link_to(link[:title], link[:url]))
      end
    helpers.content_tag(
      :section,
      class: "wiki-related-card",
      data: {
        wiki_related_card: true
      },
      aria: {
        labelledby: "wiki-related-heading"
      }
    ) do
      helpers.safe_join(
        [
          helpers.content_tag(:h3, card[:heading], id: "wiki-related-heading"),
          helpers.content_tag(:ul, helpers.safe_join(items))
        ]
      )
    end
  end
end
