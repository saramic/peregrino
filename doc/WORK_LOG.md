# WORK LOG

# Tue 16 June 2026

## 1. Setup tools and build

```sh
mise use ruby 4.0.5

# create Makefile and mise.toml

make check
# which runs
mise run check

# also have
mise run install
mise run check-tools
mise run setup
```

added a CI step via github actions
- [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

## 2. Rails New

with:

```sh
# From inside your peregrino/ repo root:
rails new . \
  --database=postgresql \
  --asset-pipeline=propshaft \
  --javascript=esbuild \
  --css=tailwind \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-jbuilder \
  --skip-test \
  --skip

# --skip tells Rails not to overwrite existing files without asking.
# Your README.md and LICENSE are preserved.
# Check the diff carefully before committing — Rails generates its own
# README stub that --skip will leave alone, but verify nothing important
# was clobbered.
```

### Why esbuild over importmap?

Bridge Components for Hotwire Native benefit from a proper build step —
tree-shaking, TypeScript support, and normal `pnpm add` for JS packages without
going through importmap's CDN pinning workflow. esbuild adds a ~2s build step
in CI. It is the right call for growing a JS surface for this app.

### Why these flags?

Solid Queue, Solid Cache, Solid Cable, and Kamal are included by default in
Rails 8 — no extra flags needed. `--skip-test` lets you drop in RSpec cleanly.
`--skip-jbuilder` because we serve HTML not JSON to mobile (Hotwire Native).
`--skip-action-mailbox` and `--skip-action-text` are almost never used on
a new project; add them back if needed.
