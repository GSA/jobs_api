module Elasticsearch; end

es_config = (YAML.load_file("#{Rails.root}/config/elasticsearch.yml") || {})[Rails.env]

Tire::Configuration.url(es_config['url']) if es_config && es_config['url'].present?

Elasticsearch::INDEX_NAME = es_config && es_config['index_name'].present? ? es_config['index_name'].freeze : "#{Rails.env}:jobs".freeze
