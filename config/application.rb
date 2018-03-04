# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'action_controller/railtie'

Bundler.require(*Rails.groups)

module JobsApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W[#{Rails.root}/lib #{Rails.root}/lib/constraints #{Rails.root}/lib/importers]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.middleware.use Rack::JSONP

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: %i[get options]
      end
    end

    config.airbrake = config_for(:airbrake)
    config.elasticsearch = config_for(:elasticsearch)
  end
end
