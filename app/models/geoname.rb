class Geoname
  include Tire::Model::Search

  index_name("#{Rails.env}:geonames".freeze)

  class << self

    def create_search_index
      Tire.index index_name do
        create(
          settings: {
            index: {
              analysis: {
                analyzer: {custom_analyzer: {type: 'custom', tokenizer: 'whitespace', filter: %w(standard lowercase synonym)}},
                filter: {synonym: {type: 'synonym', synonyms_path: "#{Rails.root.join('config', 'geonames_synonyms.txt')}"}}
              }
            }
          },
          mappings: {
            geoname: {
              properties: {
                type: {type: 'string'},
                location: {type: 'string', analyzer: 'custom_analyzer'},
                state: {type: 'string', analyzer: 'keyword'},
                geo: {type: 'geo_point'},
                id: {type: 'string', index: :not_analyzed, include_in_all: false}
              }
            }
          }
        )
      end
    end

    def geocode(options = {})
      search_for(options.merge(size: 1)).results.first.geo.to_hash rescue nil
    end

    def search_for(options)
      Tire.search index_name do
        query do
          boolean do
            must { match :location, options[:location], operator: 'AND' }
            must { term :state, options[:state] }
          end
        end
        size options[:size]
      end
    end

    def delete_search_index
      search_index.delete
    end

    def search_index
      Tire.index(index_name)
    end

    def import(geonames)
      Tire.index index_name  do
        import geonames do |docs|
          docs.each do |doc|
            doc[:id] = "#{doc[:location]}:#{doc[:state]}"
          end
        end
        refresh
      end

      #Tire.index index_name
      Rails.logger.info "Imported #{geonames.size} Geonames to #{index_name}"
    end

  end
end