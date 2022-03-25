# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.5] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.4] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.3] - 2026-03-23

### Fixed
- Standardize README to match template guide

## [0.1.2] - 2026-03-22

### Changed
- Expand test coverage to 43 examples

## [0.1.1] - 2026-03-22

### Changed
- Fix README badges

## [0.1.0] - 2026-03-21

### Added
- Initial release
- `Try.call` for wrapping risky expressions
- `Success` and `Failure` result types
- `.or_else` for default values on failure
- `.or_try` for chained recovery attempts
- `.on(ExceptionClass)` for specific error handling
- `.on_error` for failure side effects
- `.map` for transforming success values
- Optional timeout support
