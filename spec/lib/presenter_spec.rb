# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseWikiRelated::Presenter do
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category: category) }

  let(:row) do
    {
      site_key: "objectivism-online",
      mapping_version: "v1",
      links: [
        { title: "A <tag> & \"quote\"", path: "/A_%3F_B", score: 150.0 },
        { title: "Unicode café", path: "/Unicode_caf%C3%A9", score: 120.0 }
      ]
    }
  end

  before do
    SiteSetting.wiki_related_enabled = true
    SiteSetting.wiki_related_wiki_base_url =
      "https://wiki.objectivismonline.com"
    SiteSetting.wiki_related_heading = "Related on the wiki"
    SiteSetting.wiki_related_max_links = 3
  end

  def card(value = row)
    described_class.new(topic, value).card
  end

  it "constructs ordered, encoded URLs and leaves escaping to the renderer" do
    expect(card).to eq(
      heading: "Related on the wiki",
      links: [
        {
          title: "A <tag> & \"quote\"",
          url:
            "https://wiki.objectivismonline.com/A_%3F_B?utm_source=forum-crosslink"
        },
        {
          title: "Unicode café",
          url:
            "https://wiki.objectivismonline.com/Unicode_caf%C3%A9?utm_source=forum-crosslink"
        }
      ]
    )
  end

  it "is inert when disabled" do
    SiteSetting.wiki_related_enabled = false
    expect(card).to be_nil
  end

  it "silently ignores a topic with no mapping row" do
    expect(Rails.logger).not_to receive(:warn)
    expect(card(nil)).to be_nil
  end

  it "rejects a row from the other site" do
    row[:site_key] = "mises-community"
    expect(card).to be_nil
  end

  it "switches safely to the Mises wiki identity" do
    SiteSetting.wiki_related_wiki_base_url = "https://wiki.freecapitalists.org"
    row[:site_key] = "mises-community"
    row[:links] = [{ title: "Money", path: "/wiki/Money", score: 120 }]
    expect(card[:links].first[:url]).to eq(
      "https://wiki.freecapitalists.org/wiki/Money?utm_source=forum-crosslink"
    )
  end

  it "rejects malformed and origin-escaping paths" do
    %w[
      https://evil.example/X
      //evil.example/X
      /../X
      /%2E%2E/X
      /X?next=evil
      /bad%zz
    ].each do |path|
      row[:links] = [{ title: "X", path: path, score: 100 }]
      expect(card).to be_nil
    end
  end

  it "rejects malformed rows instead of partially rendering" do
    row[:links] << { title: "Broken", path: "https://evil.example", score: 100 }
    expect(card).to be_nil
    expect(card("not json")).to be_nil
  end

  it "never presents private, read-restricted, unlisted, or deleted topics" do
    topic.update!(category_id: nil, archetype: Archetype.private_message)
    expect(card).to be_nil
    topic.update!(
      archetype: Archetype.default,
      category: category,
      visible: false
    )
    expect(card).to be_nil
    topic.update!(visible: true, deleted_at: Time.zone.now)
    expect(card).to be_nil
    topic.update!(deleted_at: nil)
    category.update!(read_restricted: true)
    expect(card).to be_nil
  end
end
