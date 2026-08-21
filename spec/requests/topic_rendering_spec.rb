# frozen_string_literal: true

require "rails_helper"

RSpec.describe "wiki-related topic rendering" do
  fab!(:topic)

  let(:stored_row) do
    {
      site_key: "objectivism-online",
      mapping_version: "v1",
      links: [
        { title: "First <unsafe>", path: "/First", score: 150 },
        { title: "Second & final", path: "/Second", score: 120 }
      ]
    }
  end

  before do
    SiteSetting.wiki_related_enabled = true
    SiteSetting.wiki_related_wiki_base_url =
      "https://wiki.objectivismonline.com"
    SiteSetting.wiki_related_heading = "Related on the wiki"
    SiteSetting.wiki_related_max_links = 3
    TopicCustomField.create!(
      topic_id: topic.id,
      name: "wiki_related",
      value: stored_row.to_json
    )
  end

  it "returns the same ordered titles and URLs to browser JSON and crawler HTML" do
    get "/t/#{topic.id}.json"
    expect(response.status).to eq(200)
    browser_card = response.parsed_body["wiki_related"]

    get "/t/#{topic.slug}/#{topic.id}",
        headers: {
          "HTTP_USER_AGENT" => "Googlebot"
        }
    expect(response.status).to eq(200)
    fragment = Nokogiri.HTML5(response.body).at_css("[data-wiki-related-card]")
    expect(fragment).to be_present
    expect(fragment.css("a").map(&:text)).to eq(
      browser_card["links"].map { |link| link["title"] }
    )
    expect(fragment.css("a").map { |node| node["href"] }).to eq(
      browser_card["links"].map { |link| link["url"] }
    )
    expect(fragment.to_html).to include("First &lt;unsafe&gt;")
    expect(fragment.to_html).to include("Second &amp; final")
  end

  it "removes both browser and crawler output immediately when disabled" do
    SiteSetting.wiki_related_enabled = false
    get "/t/#{topic.id}.json"
    expect(response.parsed_body).not_to have_key("wiki_related")

    get "/t/#{topic.slug}/#{topic.id}",
        headers: {
          "HTTP_USER_AGENT" => "Googlebot"
        }
    expect(response.body).not_to include("data-wiki-related-card")
  end

  it "shows no card on an unmatched topic" do
    TopicCustomField.where(topic_id: topic.id, name: "wiki_related").delete_all
    get "/t/#{topic.slug}/#{topic.id}",
        headers: {
          "HTTP_USER_AGENT" => "Googlebot"
        }
    expect(response.body).not_to include("data-wiki-related-card")
  end
end
