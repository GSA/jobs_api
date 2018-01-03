module Elasticsearch; end

Rails.application.config.elasticsearch = (YAML.load_file("#{Rails.root}/config/elasticsearch.yml") || {})[Rails.env]

config = Rails.application.config.elasticsearch

Elasticsearch::INDEX_NAME = config && config['index_name'].present? ? config['index_name'].freeze : "#{Rails.env}:jobs".freeze

if Rails.env.production?
  Rails.application.config.elasticsearch_client = Elasticsearch::Client.new(
    host: [{
      url: config['url'],
      user: config['username'],
      password: config['password']
    }]
  )
else
  Rails.application.config.elasticsearch_client = Elasticsearch::Client.new(
    host: config['host'],
    log: true
  )
end

PositionOpening.create_search_index unless PositionOpening.search_index_exists?
Geoname.create_search_index unless Geoname.search_index_exists?
