airbrake_config = YAML.load_file("#{Rails.root}/config/airbrake.yml")
Airbrake.configure do |config|
  config.api_key = airbrake_config['api_key']
end
