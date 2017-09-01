source 'https://rubygems.org'

gem 'rails', '3.2.22.5'
gem 'rails-api', '~> 0.1.0'
gem 'nokogiri', '~> 1.8.0'
gem 'tire', '~> 0.6.2' #deprecated in 2013
gem 'tire-contrib', '~> 0.1.2'
gem 'oj', '~> 3.1.3'
gem 'faraday_middleware', '~> 0.9.0'
gem 'net-http-persistent', '~> 2.8'
gem 'airbrake', '~> 3.1.12'
gem 'rack-contrib', '~> 1.1.0'
gem 'jbuilder', '~> 1.4.1'
gem 'rack-cors', '~> 0.3.1'
gem 'us_states', '~> 0.1.1', git: 'https://github.com/GSA/us_states.git'
gem 'newrelic_rpm', '~> 3.6.3.104'

# Temporarily limiting rake version:
# #http://stackoverflow.com/questions/35893584/nomethoderror-undefined-method-last-comment-after-upgrading-to-rake-11
gem 'rake', '~> 10.0'

group :development, :test do
  gem 'rspec-rails', '~> 2.99.0'
  gem 'thin', '~> 1.7.1'
end

gem 'capistrano', '~> 2.15.4', group: :development
gem 'coveralls', '~> 0.7.0', require: false

group :test do
  gem 'shoulda-matchers', '~> 2.7.0'
  gem 'simplecov', '~> 0.8.2', :require => false
  gem 'simplecov-rcov', '~> 0.2.3', :require => false
  gem 'test-unit', '~> 3.0'
end
