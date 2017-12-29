module Elasticsearch; end

es_config = Rails.application.config.elasticsearch_config

Elasticsearch::INDEX_NAME = es_config && es_config['index_name'].present? ? es_config['index_name'].freeze : "#{Rails.env}:jobs".freeze
