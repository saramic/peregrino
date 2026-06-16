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

### 3. Switch to PNPM

Install and check versions of `pnpm` and `node`

```sh
mise use pnpm@10
mise use node@24
```

update rails to use `pnpm`

```sh
# Remove any yarn.lock or package-lock.json Rails may have created
rm -f yarn.lock package-lock.json

# Fix Procfile.dev — Rails generates: js: yarn build --watch
# Change to pnpm:
sed -i '' 's/yarn build/pnpm build/g' Procfile.dev

# Install with pnpm (generates pnpm-lock.yaml)
pnpm install

# Verify the bridge package installs cleanly
pnpm add @hotwired/hotwire-native-bridge
```

### 4. RSpec for testing

base testing setup

```sh
bundle add rspec-rails --group "development, test"
bin/rails generate rspec:install
bundle binstub rspec-core

bin/rspec

# run in check
make check
```

### 5. Rubocop for ruby linting

seems like this is somewhat setup already

```sh
bundle exec rubocop
# now part of
make check
```

### 6. ESLint + Prettier

Add linting for the JavaScript side — bridge components, Lambda functions, and
any future TypeScript. A shared config at the root covers all three.

```bash
# Install at repo root
pnpm add -D eslint @eslint/js eslint-plugin-import prettier \
  eslint-config-prettier eslint-plugin-prettier
```

Create eslint.config.js at repo root (ESLint flat config format, the default since ESLint 9):

Create `.prettierrc` at repo root:

```json
{
  "semi": false,          # no longer needed as ASI (Automatic Semicolon Insertion fixes it)
  "singleQuote": true,    # becuase more Rails like but not like JSON
  "trailingComma": "es5", # because all will put into functions as well
  "printWidth": 100       # because 80 is too tight
}
```

talked AI down and just went for `.prettierrc` as below

```json
{}
```

added `pnpm lint` and `pnpm format` scrits