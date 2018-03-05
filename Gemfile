# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'airbrake', '~> 7.1'
gem 'elasticsearch-dsl'
gem 'elasticsearch-model'
gem 'elasticsearch-rails'
gem 'faraday_middleware', '~> 0.12.2'
gem 'jbuilder', '~> 2.7.0'
gem 'net-http-persistent', '~> 2.8'
gem 'newrelic_rpm', '~> 4.6.0'
gem 'nokogiri', '~> 1.8.0'
gem 'oj', '~> 3.1.3' # Unused?
gem 'rack-contrib', '~> 2.0.1'
gem 'rack-cors', '~> 1.0.2'
gem 'rails', '5.1.4'
gem 'rails-controller-testing', '~> 1.0'
gem 'rake', '~> 11.0'
gem 'us_states', '~> 0.1.1', git: 'https://github.com/GSA/us_states.git'
gem 'whenever'

group :development, :test do
  gem 'puma', '~> 3.7'
  gem 'rspec-rails', '~> 3.7'
  gem 'rubocop'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'capistrano', '~> 2.15.4', group: :development

group :test do
  gem 'shoulda-matchers', '~> 2.7.0'
  gem 'simplecov', '~> 0.8.2', require: false
  gem 'simplecov-rcov', '~> 0.2.3', require: false
  gem 'test-unit', '~> 3.0'
end
