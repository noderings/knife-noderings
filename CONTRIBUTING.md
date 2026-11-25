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
