# WORK LOG

# Tue 16 June 2026

## Setup tools and build

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
