module Elasticsearch
  es_config = (YAML.load_file("#{Rails.root}/config/elasticsearch.yml") || {})[Rails.env]
  INDEX_NAME = es_config && es_config['index_name'].present? ? es_config['index_name'].freeze : "#{Rails.env}:jobs".freeze
end