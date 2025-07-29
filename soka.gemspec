# frozen_string_literal: true

require_relative 'lib/soka/version'

Gem::Specification.new do |spec|
  spec.name = 'soka'
  spec.version = Soka::VERSION
  spec.authors = ['jiunjiun']
  spec.email = ['imjiunjiun@gmail.com']

  spec.summary = 'A Ruby ReAct Agent Framework with multi-LLM support'
  spec.description = 'Soka is a Ruby framework for building AI agents using the ReAct (Reasoning and Acting) ' \
                     'pattern. It supports multiple AI providers including Gemini AI Studio, OpenAI, and Anthropic.'
  spec.homepage = 'https://github.com/jiunjiun/soka'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/jiunjiun/soka'
  spec.metadata['changelog_uri'] = 'https://github.com/jiunjiun/soka/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'dry-struct', '~> 1.6'
  spec.add_dependency 'dry-types', '~> 1.7'
  spec.add_dependency 'dry-validation', '~> 1.10'
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'zeitwerk', '~> 2.6'
end
