# Changelog

## 1.3

Elixometer now requires Elixir 1.5 or later.

- Enhancements

  - Made the histogram `truncate` option a function argument for `update_histogram/4` (#56)
  - Made metric name formatting more efficient (#62, #74)
  - Support passing extra `subscribe_options` to reporters that accept them (#57, #58)
  - Support all Elixir time units (#72)
  - Support using system environment variables in `:env` configuration (#80)
  - Support filtering datapoints in subscriptions (#91)
  - Support wildcard keys (#97)
  - Add typespecs to public Elixometer methods (#107)
  - Support configuring the formatter using a module in addition to a function ref (#114)

- Bug fixes

  - Fix `@timed` function attribute to correctly time function body (#100, #101)
