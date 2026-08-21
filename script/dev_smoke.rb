# frozen_string_literal: true

# Create or remove a deliberately hand-written development topic/custom-field
# pair for browser and crawler smoke tests. Never run this against production.

require "json"

if !Rails.env.development?
  raise "development smoke fixture refuses outside development"
end

marker = "[wiki-related-smoke]"
if ENV["SMOKE_ACTION"] == "cleanup"
  Topic.where("title LIKE ?", "#{marker}%").find_each(&:destroy!)
  puts "wiki-related smoke fixtures removed"
  exit
end

config = {
  "objectivism-online" => {
    base_url: "https://wiki.objectivismonline.com",
    path: "/Ayn_Rand"
  },
  "mises-community" => {
    base_url: "https://wiki.freecapitalists.org",
    path: "/wiki/Ludwig_von_Mises"
  }
}.fetch(ENV.fetch("WIKI_SITE"))

Topic.where("title LIKE ?", "#{marker}%").find_each(&:destroy!)
owner = User.find_by(id: -1) || raise("system user is missing")
category =
  Category
    .where(read_restricted: false)
    .where.not(id: SiteSetting.uncategorized_category_id)
    .first || Category.find_by(id: SiteSetting.uncategorized_category_id) ||
    raise("public category is missing")
post =
  PostCreator.create!(
    owner,
    title: "#{marker} #{ENV.fetch("WIKI_SITE")}",
    raw:
      "Hand-written row for the discourse-wiki-related development smoke test.",
    category: category.id
  )
topic = post.topic
row = {
  site_key: ENV.fetch("WIKI_SITE"),
  mapping_version: "v1",
  links: [
    {
      title: "Quotes <angles> & Unicode: Mises’",
      path: config.fetch(:path),
      score: 200
    }
  ]
}
TopicCustomField.create!(
  topic_id: topic.id,
  name: "wiki_related",
  value: JSON.generate(row)
)

SiteSetting.login_required = false
SiteSetting.wiki_related_wiki_base_url = config.fetch(:base_url)
SiteSetting.wiki_related_heading = "Related on the wiki"
SiteSetting.wiki_related_max_links = 3
SiteSetting.wiki_related_enabled = true

puts JSON.generate(
       topic_id: topic.id,
       slug: topic.slug,
       site_key: ENV.fetch("WIKI_SITE")
     )
