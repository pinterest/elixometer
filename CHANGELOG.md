# Changelog

## [Unreleased]

### Added

- Made the histogram `truncate` option a function argument for `update_histogram/4`
- Support passing extra `subscribe_options` to reporters that accept them
- Made metric name formatting more efficient
- Support all Elixir time units
- Support using system environment variables in `:env` configuration
- Support filtering datapoints in subscriptions
- Support wildcard keys
- Add typespecs to public Elixometer methods
- Support configuring the formatter using a module in addition to a function ref

### Changed

- Elixometer now requires Elixir 1.5 or later.

### Fixed

- Fix `@timed` function attribute to correctly time function body
  ([#100](https://github.com/pinterest/elixometer/pull/100),
  [#101](https://github.com/pinterest/elixometer/pull/101))

[Unreleased]: https://github.com/pinterest/elixometer/compare/1.2.1...HEAD
