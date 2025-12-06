# Nakedible.org

Personal website built with Zola using the [Serene](https://github.com/isunjn/serene) theme (v5.5.0).

## Commands

```bash
./serve.sh           # Dev server (drafts enabled)
./resume-build.sh    # Rebuild resume CSS + PDFs
./resume-watch.sh    # Watch mode for resume dev
```

## Key Files

- `config.toml` - Site config
- `content/_index.md` - Homepage (name, bio, links)
- `content/articles/YYYY-MM-DD_slug/index.md` - Articles
- `templates/resume.html` - Resume (standalone Tailwind page)
- `themes/serene/` - Theme submodule

## Articles

```markdown
+++
title = "Title"
[taxonomies]
categories = ["cloud"]  # cloud, security, fun
[extra]
toc = true
+++
```

Use `draft = true` to hide from production.

## Deployment

Cloudflare Pages auto-deploys from `master` to https://nakedible.org

Build: `zola build` (with `ZOLA_VERSION=0.21.0`, `PROD=1` for production)
