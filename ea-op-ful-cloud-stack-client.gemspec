# frozen_string_literal: true

require_relative 'lib/ea-op-ful-cloud-stack-client/version'

Gem::Specification.new do |spec|
  spec.name = 'ea-op-ful-cloud-stack-client'
  spec.version = EaOpFulCloudstackClient::VERSION
  spec.authors = ['Enterprise Applications']
  spec.email = ['enterpriseapplications@locaweb.com.br']

  spec.summary = 'Cloudstack client'
  spec.description = 'Cloudstack client'
  spec.homepage = 'https://dev.azure.com/locaweb/apps-ea-op-ful-cloud/_git/ea-op-ful-cloud-stack-client'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'geminabox'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop'
end
