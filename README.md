# philiprehberger-try

[![Tests](https://github.com/philiprehberger/rb-try/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-try/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-try.svg)](https://rubygems.org/gems/philiprehberger-try)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-try)](https://github.com/philiprehberger/rb-try/commits/main)

Concise error handling with fallbacks, chained recovery, and timeout wrapping

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-try"
```

Or install directly:

```bash
gem install philiprehberger-try
```

## Usage

```ruby
require "philiprehberger/try"
```

### Basic wrapping

Wrap any risky expression with `Try.call`. It returns a `Success` or `Failure`:

```ruby
result = Philiprehberger::Try.call { Integer("42") }
result.success? # => true
result.value    # => 42

result = Philiprehberger::Try.call { Integer("nope") }
result.failure? # => true
result.error    # => #<ArgumentError: invalid value for Integer(): "nope">
```

### Default values with `or_else`

Provide a fallback value when the operation fails:

```ruby
value = Philiprehberger::Try.call { Integer("nope") }
  .or_else(0)
  .value

value # => 0
```

### Chained recovery with `or_try`

Chain multiple recovery strategies. The first success wins:

```ruby
result = Philiprehberger::Try
  .call { fetch_from_cache(key) }
  .or_try { fetch_from_database(key) }
  .or_try { fetch_from_api(key) }

result.value! # returns the first successful result or raises
```

### Handling specific exceptions with `on`

Recover from specific exception types:

```ruby
result = Philiprehberger::Try.call { parse_config(path) }
  .on(Errno::ENOENT) { |_e| default_config }
  .on(JSON::ParserError) { |e| raise ConfigError, "Invalid JSON: #{e.message}" }
```

### Side effects with `on_error`

Log or report errors without changing the result:

```ruby
result = Philiprehberger::Try.call { risky_operation }
  .on_error { |e| logger.warn("Operation failed: #{e.message}") }
  .or_else(fallback)
```

### Transforming values with `map`

Transform a successful value. Failures propagate unchanged:

```ruby
result = Philiprehberger::Try.call { File.read("data.json") }
  .map { |contents| JSON.parse(contents) }
  .map { |data| data.fetch("key") }

result.value # => parsed value or nil if any step failed
```

### Chaining with `flat_map`

Chain operations that return Try results without double-wrapping:

```ruby
result = Philiprehberger::Try.call { "42" }
  .flat_map { |v| Philiprehberger::Try.call { Integer(v) } }
  .flat_map { |v| Philiprehberger::Try.call { v * 2 } }

result.value # => 84
```

### Recovering from errors

Transform a failure into a success based on the error:

```ruby
result = Philiprehberger::Try.call { raise ArgumentError, "bad input" }
  .recover { |e| "default value" }

result.value # => "default value"
```

### Side effects with `tap`

Execute side effects without changing the result:

```ruby
result = Philiprehberger::Try.call { 42 }
  .tap { |r| puts "Got: #{r.value}" }

result.value # => 42
```

### Timeout support

Add a timeout constraint to any operation:

```ruby
result = Philiprehberger::Try.call(timeout: 5) { slow_http_request }

result.failure? # => true if it took longer than 5 seconds
result.error    # => #<Timeout::Error: execution expired>
```

## API

| Method | On Success | On Failure |
|---|---|---|
| `Try.call(timeout: nil) { block }` | Returns `Success` wrapping block result | Returns `Failure` wrapping exception |
| `#value` | Returns the wrapped value | Returns `nil` |
| `#value!` | Returns the wrapped value | Raises the stored exception |
| `#success?` | `true` | `false` |
| `#failure?` | `false` | `true` |
| `#error` | N/A | Returns the stored exception |
| `#or_else(default)` | Returns self | Returns `Success.new(default)` |
| `#or_try { block }` | Returns self | Calls `Try.call` with the block |
| `#on(ExceptionClass) { block }` | Returns self | If error matches, returns `Try.call { block }` |
| `#on_error { block }` | Returns self | Calls block for side effect, returns self |
| `#map { block }` | Wraps block result in new `Try.call` | Returns self |
| `#flat_map { block }` | Chains block returning Try | Returns self |
| `#recover { block }` | Returns self | Wraps block result in `Try.call` |
| `#tap { block }` | Calls block, returns self | Calls block, returns self |
| `#transform(on_success:, on_failure:)` | Applies `on_success` lambda | Applies `on_failure` lambda |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-try)

🐛 [Report issues](https://github.com/philiprehberger/rb-try/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-try/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
