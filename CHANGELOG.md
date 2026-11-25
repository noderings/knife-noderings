# Changelog

All notable changes to this project are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-11-25

### Added

- `knife noderings server create`: orders a NodeRings virtual machine from the
  marketplace (the cheapest matching offer, the best rated, or an exact plan and
  region), attaches a firewall ruleset, waits for SSH and bootstraps Chef Infra
  or Cinc with every `knife bootstrap` option (run list, policy, environment).
- `knife noderings server list`, `show`, `start`, `stop`, `reboot` and `delete`
  (with `--purge` to remove the Chef node and client).
- `knife noderings plan list`, `region list`, `distro list` and `ssh key list`.
- Orders are idempotent: a lost response is retried with the same idempotency
  key, so a server is never ordered twice.
