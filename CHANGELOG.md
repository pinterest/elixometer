# Changelog

## 1.5.0

### Changed

- The minimum supported Elixir version is now 1.7
- Elixometer no longer depends on Lager

## 1.4.1

### Added

- Support for Elixir 1.12 and OTP 24

## 1.4.0

### Added

- Support for Elixir 1.10 and Elixir 1.11

## 1.3.0

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
- Support for bulk subscriptions to get all metrics at once

### Changed

- Elixometer now requires Elixir 1.5 or later.
- Lager 3.2.1 or later is now required.
- :exometer_core 1.5 or later is now required.

### Fixed

- Fix `@timed` function attribute to correctly time function body
  ([#100](https://github.com/pinterest/elixometer/pull/100),
  [#101](https://github.com/pinterest/elixometer/pull/101))
