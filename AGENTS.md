# AGENTS.md

Canonical instructions for this plugin. `CLAUDE.md` points here.

| Task | Read |
|---|---|
| Purpose, settings, and local test command | `README.md` |
| Rendering and validation contract | `lib/discourse_wiki_related/presenter.rb`, then `spec/` |

This plugin renders precomputed `wiki_related` topic custom fields. It never searches or requests
a wiki at topic-render time. Keep the browser serializer and crawler builder on the same validated
presenter output, keep every setting per-site and default-off, and suppress malformed, wrong-site,
or non-public topic data. Test changes from a Discourse checkout with this repository installed at
`plugins/discourse-wiki-related`; run both `bin/lint plugins/discourse-wiki-related` and
`bin/rspec plugins/discourse-wiki-related/spec`.
