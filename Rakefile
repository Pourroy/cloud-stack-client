# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]


task :publish do
  puts `gem inabox -g http://gems.locaweb.com.br/ pkg/ea-op-ful-cloud-stack-client-*#{EaOpFulCloudstackClient::VERSION}.gem`
end
