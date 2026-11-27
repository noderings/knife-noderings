# Changelog

All notable changes to this project are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [0.2.1](https://github.com/noderings/knife-noderings/compare/v0.2.0...v0.2.1) (2026-11-27)


### Documentation

* link the official Go SDK in the README ([#8](https://github.com/noderings/knife-noderings/issues/8)) ([1397c04](https://github.com/noderings/knife-noderings/commit/1397c04e5e7dbb33e2e7ed1303f97efc8af5117c))

## [0.2.0](https://github.com/noderings/knife-noderings/compare/v0.1.0...v0.2.0) (2026-11-26)


### Features

* choose the provider in knife noderings server create ([#5](https://github.com/noderings/knife-noderings/issues/5)) ([f79d5c2](https://github.com/noderings/knife-noderings/commit/f79d5c2e7a4d5504747a6edb62ec438915c32188))

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
