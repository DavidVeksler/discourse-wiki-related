# discourse-wiki-related

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Discourse](https://img.shields.io/badge/Discourse-plugin-blue.svg)](https://www.discourse.org/)

A minimal [Discourse](https://www.discourse.org/) plugin that renders precomputed, site-scoped
"related on the wiki" links on public topic pages. It never queries a wiki, computes similarity,
or matches content at render time — a validated `wiki_related` `TopicCustomField`, populated by an
external job, supplies the ordered links. The plugin's only job is to present that data safely.

In the browser, the links appear as a compact reference strip below the topic title and category,
before the first post. The crawler view carries the same ordered links after the posts through
Discourse's server-rendered HTML hook.

## Why

Communities that run a companion MediaWiki alongside their Discourse forum want topic pages to
surface relevant wiki articles. Doing that lookup live, on every page view, is unnecessary work and
an unnecessary trust boundary. This plugin keeps rendering dumb and fast: a precomputation step
(cron job, admin script, whatever) writes the related links to a topic custom field, and this
plugin only ever displays what's already there — after validating it.

## What it guards against

The presenter (`lib/discourse_wiki_related/presenter.rb`) fails closed and suppresses the card
entirely rather than rendering anything malformed:

- rows written for a different community (`site_key` mismatch)
- links pointing outside an allow-listed wiki origin (host + scheme + no userinfo/port/query)
- malformed or missing stored JSON
- private, unlisted, deleted, read-restricted, or non-public topics
- personal messages (only the default archetype is eligible)

The browser serializer and the crawler-facing HTML builder (`server:topic-show-after-posts-crawler`)
both call the same presenter, so logged-in users, anonymous visitors, and search-engine crawlers see
identical, identically-validated links.

## Installation

Add the plugin to your Discourse container the standard way — either clone it into
`containers/<container>.yml` under `plugins:` (see the
[Discourse install-plugin guide](https://meta.discourse.org/t/install-a-plugin/19157)) as:

```yaml
- git clone https://github.com/DavidVeksler/discourse-wiki-related.git
```

or, for a development checkout, clone directly into `plugins/`:

```bash
cd plugins
git clone https://github.com/DavidVeksler/discourse-wiki-related.git
```

Then rebuild/restart Discourse.

## Configuration

The plugin is inert after installation. Configure these site settings per Discourse site
(Admin → Settings → Plugins):

| Setting | Purpose | Default |
|---|---|---|
| `wiki_related_enabled` | Master on/off switch | `false` |
| `wiki_related_wiki_base_url` | Allow-listed wiki origin (`https://` scheme, no path/query) | `""` |
| `wiki_related_heading` | Card heading text | `Related on the wiki` |
| `wiki_related_max_links` | Max links shown (1–3) | `3` |

Enable `wiki_related_enabled` last, after the base URL is set and a site is registered in
`EXPECTED_SITE_BY_HOST`.

## Test

From a Discourse checkout with this repository installed at `plugins/discourse-wiki-related`:

```bash
bin/lint plugins/discourse-wiki-related
bin/rspec plugins/discourse-wiki-related/spec
```

## Development

See [AGENTS.md](AGENTS.md) for the doc-routing table used by coding agents working in this repo.

MIT licensed.
