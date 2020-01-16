# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rabbitek/version'

Gem::Specification.new do |spec|
  spec.name          = 'rabbitek'
  spec.version       = Rabbitek::VERSION
  spec.authors       = ['Boostcom']
  spec.email         = ['jakub.kruczek@boostcom.no']

  spec.summary       = 'High performance background job processing'
  spec.description   = 'High performance background job processing'
  spec.homepage      = 'http://boostcom.no'

  spec.license = 'MIT'

  spec.metadata['source_code_uri'] = 'https://github.com/Boostcom/rabbitek'
  spec.metadata['changelog_uri'] = 'https://github.com/Boostcom/rabbitek/blob/master/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/Boostcom/rabbitek/issues'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '> 3.0'
  spec.add_dependency 'bunny', '~> 2.11.0'
  spec.add_dependency 'oj', '~> 3.6'
  spec.add_dependency 'opentracing', '~> 0.4'
  spec.add_dependency 'slop', '~> 4.0'
  spec.add_dependency 'yabeda'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rails', '~> 5'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.58.0'
end
