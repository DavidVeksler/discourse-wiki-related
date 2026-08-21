# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseWikiRelated do
  let(:plugin_root) { File.expand_path("..", __dir__) }
  let(:connectors_root) do
    File.join(plugin_root, "assets/javascripts/discourse/connectors")
  end

  it "renders beside the topic title instead of below the entire post stream" do
    expect(File).to exist(
      File.join(connectors_root, "topic-title/wiki-related.gjs")
    )
    expect(File).not_to exist(
      File.join(connectors_root, "topic-above-suggested/wiki-related.gjs")
    )
  end
end
