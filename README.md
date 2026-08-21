# discourse-wiki-related

A deliberately small Discourse plugin that renders precomputed, site-bound wiki links on public
topic pages. It performs no live wiki request and no matching. A validated `wiki_related`
`TopicCustomField` supplies the ordered links.

The plugin is inert after installation. Configure these settings separately in each Discourse
site database:

- `wiki_related_wiki_base_url`
- `wiki_related_heading`
- `wiki_related_max_links`
- `wiki_related_enabled` (defaults to `false`; enable last)

Rows for another community, unsafe paths, malformed values, private/read-restricted/unlisted/
deleted topics, and unsupported wiki hosts fail closed. The browser connector and crawler HTML
builder share the same Ruby presenter, so they receive identical ordered titles and URLs.

## Test

From a Discourse checkout with this repository at `plugins/discourse-wiki-related`:

```bash
bundle exec rspec plugins/discourse-wiki-related/spec
```

MIT licensed.

