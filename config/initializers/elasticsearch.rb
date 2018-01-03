module Elasticsearch; end

config = Rails.application.config.elasticsearch

Elasticsearch::INDEX_NAME = config && config['index_name'].present? ? config['index_name'].freeze : "#{Rails.env}:jobs".freeze

Rails.application.config.elasticsearch_client = Elasticsearch::Client.new(
  url: config['url'],
  host: config['host'],
  user: config['username'],
  password: config['password']
)

PositionOpening.create_search_index unless PositionOpening.search_index_exists?
Geoname.create_search_index unless Geoname.search_index_exists?
