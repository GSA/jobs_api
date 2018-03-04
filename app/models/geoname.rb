# frozen_string_literal: true

require 'active_model'
require 'elasticsearch/dsl'

class Geoname
  include ActiveModel::Model
  include Elasticsearch::Model
  include Elasticsearch::DSL

  INDEX_NAME = "#{Rails.env}:geonames"

  SYNONYMS = [
    'afb, air force base',
    'afs, air force station',
    'ang, air national guard',
    'cavecreek, cave creek',
    'ft, fort',
    'junc, junction',
    'natl, nat, national',
    'newcastle, new castle',
    'pk, park',
    'spgs, springs',
    'st, saint'
  ].freeze

  SETTINGS = {
    analysis: {
      filter: {
        synonym: {
          type: 'synonym',
          synonyms: SYNONYMS
        }
      },
      analyzer: {
        custom_analyzer: {
          type: 'custom',
          tokenizer: 'whitespace',
          filter: %w[standard lowercase synonym]
        }
      }
    }
  }.freeze

  settings index: SETTINGS do
    mappings dynamic: 'false' do
      indexes :type, type: 'keyword'
      indexes :location, type: 'text', analyzer: 'custom_analyzer'
      indexes :state, type: 'text', analyzer: 'keyword'
      indexes :geo, type: 'geo_point'
      indexes :id, type: 'keyword', index: false
    end
  end

  class << self
    def client
      @client ||= Geoname.__elasticsearch__.client
    end

    def create_search_index
      client.indices.create(
        index: INDEX_NAME,
        body: { settings: settings.to_hash, mappings: mappings.to_hash }
      )
    end

    def geocode(options = {})
      search_for(options.merge(size: 1)).results.first.geo
    rescue StandardError
      nil
    end

    def search_for(options)
      search_definition = Elasticsearch::DSL::Search.search do
        query do
          bool do
            must do
              match :location do
                query options[:location]
                operator 'and'
              end
            end

            must { term state: options[:state] }
          end
        end

        size options[:size]
      end.to_hash

      Geoname.search(search_definition, index: INDEX_NAME)
    end

    def delete_search_index
      client.indices.delete index: INDEX_NAME if search_index_exists?
    end

    def search_index_exists?
      client.indices.exists? index: INDEX_NAME
    end

    def import(geonames)
      geonames.each do |doc|
        client.index(
          index: INDEX_NAME,
          type: 'geoname',
          id: "#{doc[:location]}:#{doc[:state]}",
          body: {
            location: doc[:location],
            geo: doc[:geo],
            state: doc[:state]
          }
        )
      end

      __elasticsearch__.refresh_index! index: INDEX_NAME

      Rails.logger.info "Imported #{geonames.size} Geonames to #{INDEX_NAME}"
    end
  end
end
