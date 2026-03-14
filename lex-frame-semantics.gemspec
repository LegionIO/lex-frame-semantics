# frozen_string_literal: true

require_relative 'lib/legion/extensions/frame_semantics/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-frame-semantics'
  spec.version       = Legion::Extensions::FrameSemantics::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Frame Semantics'
  spec.description   = "Fillmore's Frame Semantics engine for LegionIO — conceptual frame activation, slot filling, and instance creation"
  spec.homepage      = 'https://github.com/LegionIO/lex-frame-semantics'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-frame-semantics'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-frame-semantics'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-frame-semantics'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-frame-semantics/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-frame-semantics.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
