# frozen_string_literal: true

require_relative 'lib/philiprehberger/try/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-try'
  spec.version = Philiprehberger::Try::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Concise error handling with fallbacks, chained recovery, and timeout wrapping'
  spec.description = 'A tiny utility for concise error handling. Wrap risky expressions with ' \
                       'Try.call, chain fallbacks with or_else and or_try, handle specific ' \
                       'exceptions, and add timeout constraints — all without verbose begin/rescue blocks.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-try'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-try'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-try/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-try/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
