# knife-noderings

[![CI](https://github.com/noderings/knife-noderings/actions/workflows/ci.yml/badge.svg)](https://github.com/noderings/knife-noderings/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/knife-noderings.svg)](https://rubygems.org/gems/knife-noderings)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

A [knife](https://docs.chef.io/workstation/knife/) plugin for
[NodeRings](https://noderings.com). It orders virtual machines from the NodeRings
marketplace and bootstraps Chef Infra (or Cinc) on them in one command, and lists,
shows, powers and deletes them.

New to it? The step-by-step guide [How to use Chef on a NodeRings VPS: cookbook, knife and Test Kitchen](https://noderings.com/blog/chef-vps) walks through a first run.

```shell
knife noderings server create --hostname web-1 \
  --plan SC-GC-1C-1G-20 --country "United States" --city Ashburn \
  --noderings-ssh-key laptop -i ~/.ssh/id_ed25519 \
  --run-list 'role[web]'
```

## Requirements

* Ruby 3.1 or later and knife 18 or later (Chef Workstation and Cinc Workstation ship both)
* A NodeRings service account token. Create one in the NodeRings console under
  **Organization → Access Control → Service accounts**.
* For `server create`: a payment method or credit on the organization (orders are
  billed), an SSH key stored in NodeRings, and a Chef Infra Server that knife can
  bootstrap against.

## Installation

```shell
chef gem install knife-noderings     # Chef Workstation
cinc gem install knife-noderings     # Cinc Workstation
gem install knife-noderings          # plain Ruby
```

## Configuration

Put the token in `config.rb` (or `knife.rb`), or export `NODERINGS_TOKEN`:

```ruby
knife[:noderings_api_token] = ENV['NODERINGS_TOKEN']
# knife[:noderings_api_url] = 'https://api.noderings.com'
# knife[:noderings_organization_id] = '...'   # for tokens that reach several organizations
```

Every command also takes `--noderings-api-token`, `--noderings-api-url` and
`--noderings-organization-id`.

## Commands

### knife noderings server create

Orders a server, waits until it is provisioned and SSH answers, then runs
`knife bootstrap` against it. All `knife bootstrap` options work, including
`--run-list`, `--policy-name`/`--policy-group`, `--environment`, `--json-attributes`,
`--bootstrap-version` and `--connection-user`.

| Option | Description |
| --- | --- |
| `--hostname NAME` | Hostname of the server. It is also the node name unless `-N` is given. Required. |
| `--plan CODE` | Plan code, such as `SC-GC-1C-1G-20`. See `knife noderings plan list`. |
| `--country COUNTRY` | Country of the offer, such as `"United States"`. |
| `--city CITY` | City of the offer, such as `Ashburn`. See `knife noderings region list`. |
| `--billing-type TYPE` | `usage` (hourly, default), `subscription` or `free`. |
| `--sort ORDER` | `price` (cheapest, default) or `rating` (best rated). |
| `--hosting-provider PROVIDER` | Only consider offers from this provider: its ID, storefront slug (such as `acme-hosting`) or name (`"Acme Hosting"`, any case). |
| `--provider-id ID` | Only consider offers from the provider with this ID. Takes precedence over `--hosting-provider`. |
| `--plan-id ID`, `--region-id ID` | An exact plan and region, instead of plan, country and city. |
| `--distro DISTRO` | Operating system, `ubuntu_24_04` by default. See `knife noderings distro list`. |
| `--noderings-ssh-key NAME` | NodeRings SSH key to install. Repeat for more. Required. |
| `-i`, `--ssh-identity-file FILE` | The private key matching one of those keys. Required. |
| `--firewall-ruleset NAME` | Firewall ruleset to attach. It must allow SSH from your workstation. |
| `--noderings-tags a,b` | Tags on the server. |
| `--server-create-timeout SECONDS` | How long to wait for the server (default 900). |

Without `--hosting-provider` knife orders the cheapest matching offer (compute
price, then rating), so the provider can change between servers. A provider name
that more than one provider uses fails; give the ID or storefront slug then.

knife connects as `root` on port 22 and accepts the new server's host key on first
use; override with `--connection-user`, `--ssh-port` and `--ssh-verify-host-key`.
The node gets an Ohai hint file named `noderings` holding the server's ID and hostname, so recipes can check `hint?('noderings')`.

The order carries an idempotency key, so a lost response is retried without
ordering a second server. If a server with the hostname already exists, the
command stops without ordering; bootstrap it with `knife bootstrap` instead.

### knife noderings server list / show

```shell
knife noderings server list
knife noderings server show web-1 -F json
```

### knife noderings server start / stop / reboot

```shell
knife noderings server stop web-1
knife noderings server start web-1
knife noderings server reboot web-1 web-2
```

Each waits until the server reaches the new state.

### knife noderings server delete

```shell
knife noderings server delete web-1 --purge
```

Asks for confirmation (skip it with `-y`). `--purge` also deletes the Chef node and
client named like the server, or as given with `-N`. Deleting an hourly server
stops its billing; a monthly subscription is cancelled without a refund.

### Catalog

```shell
knife noderings region list                                   # countries and cities
knife noderings plan list --country "United States" --city Ashburn
knife noderings distro list                                   # operating systems
knife noderings ssh key list                                  # keys for --noderings-ssh-key
```

Every list command supports `-F json` and `-F yaml`.

## Development

```shell
bundle install
bundle exec rake          # Chefstyle and the unit tests
```

The unit tests run against an in-memory NodeRings API, so they need no token. The
plugin talks to the API with the Ruby standard library only. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

Copyright NodeRings. Licensed under the [Apache License, Version 2.0](LICENSE).
