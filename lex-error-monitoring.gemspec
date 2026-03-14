# frozen_string_literal: true

require_relative 'lib/legion/extensions/error_monitoring/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-error-monitoring'
  spec.version       = Legion::Extensions::ErrorMonitoring::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Error Monitoring'
  spec.description   = "Gehring's Error-Related Negativity (ERN) for brain-modeled agentic AI — " \
                       'automatic error detection, conflict monitoring, post-error slowing, ' \
                       'correction tracking, and confidence adjustment implementing the ' \
                       "anterior cingulate cortex's quality assurance function."
  spec.homepage      = 'https://github.com/LegionIO/lex-error-monitoring'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-error-monitoring'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-error-monitoring'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-error-monitoring'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-error-monitoring/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-error-monitoring.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
