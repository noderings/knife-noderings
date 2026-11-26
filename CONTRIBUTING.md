# Contributing

Thanks for helping improve knife-noderings.

1. Open an issue describing the bug or change before large pull requests.
2. Fork the repository and create a topic branch.
3. Run `bundle exec rake`; unit tests and Chefstyle must pass.
4. Add tests for new behaviour. Unit tests use the in-memory API in
   `spec/support/fake_noderings.rb`, so they need no token.
5. Use [Conventional Commits](https://www.conventionalcommits.org/) for commit
   messages, and sign off each commit (`git commit -s`) to certify the
   [Developer Certificate of Origin](https://developercertificate.org/).

To try a change against the real API, build and install the gem
(`gem build knife-noderings.gemspec && gem install ./knife-noderings-*.gem`),
export `NODERINGS_TOKEN`, and run `knife noderings server list`, or `knife noderings server create` against a Chef Infra Server. This orders real,
billed servers.

Please report security problems privately as described in [SECURITY.md](SECURITY.md).

## Releases

Push a `vX.Y.Z` tag that matches `KnifeNoderings::VERSION` (or merge the
release-please pull request once that workflow is in place). The tag starts
`.github/workflows/release.yml`, which publishes the gem to
[RubyGems.org](https://rubygems.org/gems/knife-noderings) with trusted
publishing and then publishes the GitHub release.

The first push of a new gem must pass the RubyGems.org account ID (`owner: "256963"`)
when exchanging the OIDC token, as already set in `release.yml`. To retry a
release, open Actions, Release, *Run workflow*, and pick the tag under
*Use workflow from*.
