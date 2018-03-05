# frozen_string_literal: true

module Elasticsearch; end

config = Rails.application.config.elasticsearch

Elasticsearch::INDEX_NAME = config && config['index_name'].present? ? config['index_name'].freeze : "#{Rails.env}:jobs"

elasticsearch_client = Elasticsearch::Client.new(
  url: config['url'],
  user: config['username'],
  password: config['password']
)

Elasticsearch::Model.client = elasticsearch_client

PositionOpening.create_search_index unless PositionOpening.search_index_exists?
Geoname.create_search_index unless Geoname.search_index_exists?
