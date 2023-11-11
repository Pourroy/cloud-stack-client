# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

task :publish do
  puts `gem push pkg/cloud-stack-client-#{CloudstackClient::VERSION}.gem --host https://rubygems.com.br`
end
