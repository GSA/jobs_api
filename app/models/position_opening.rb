class PositionOpening
  include Tire::Model::Search

  index_name("#{Rails.env}:jobs")

  MAX_RETURNED_DOCUMENTS = 100

  class << self

    def create_search_index
      Tire.index index_name do
        create(
          settings: {
            index: {
              analysis: {
                analyzer: {custom_analyzer: {type: 'custom', tokenizer: 'whitespace', filter: %w(standard lowercase synonym snowball)}},
                filter: {synonym: {type: 'synonym', synonyms_path: "#{Rails.root.join('config', 'synonyms.txt')}"}}
              }
            }
          },
          mappings: {
            position_opening: {
              _ttl: {enabled: true},
              properties: {
                type: {type: 'string'},
                position_title: {type: 'string', analyzer: 'custom_analyzer', term_vector: 'with_positions_offsets', store: true},
                organization_id: {type: 'string', analyzer: 'keyword'},
                organization_name: {type: 'string', index: :not_analyzed},
                locations: {type: 'nested', properties: {city: {type: 'string', analyzer: 'simple'}, state: {type: 'string', analyzer: 'keyword'}}},
                start_date: {type: 'date', format: 'YYYY-MM-dd'},
                end_date: {type: 'date', format: 'YYYY-MM-dd'},
                minimum: {type: 'integer'},
                maximum: {type: 'integer'},
                position_schedule_type_code: {type: 'integer'},
                rate_interval_code: {type: 'string', analyzer: 'keyword'},
                id: {type: 'integer', index: :not_analyzed, include_in_all: false}
              }
            }
          }
        )
      end
    end

    def search_for(options = {})
      options.reverse_merge!(size: 10, from: 0)
      document_limit = [options[:size].to_i, MAX_RETURNED_DOCUMENTS].min
      query = Query.new(options[:query], options[:organization_id])
      search = Tire.search index_name do
        query do
          boolean do
            must { match :position_schedule_type_code, query.position_schedule_type_code } if query.position_schedule_type_code.present?
            must { match :position_title, query.keywords, analyzer: 'custom_analyzer' } if query.keywords.present?
            must { match :rate_interval_code, query.rate_interval_code } if query.rate_interval_code.present?
            must { send(query.organization_format, :organization_id, query.organization_id) } if query.organization_id.present?
            must do
              nested path: 'locations' do
                query do
                  boolean do
                    must { term 'locations.state', query.location.state } if query.has_state?
                    must { match 'locations.city', query.location.city, operator: 'AND' } if query.has_city?
                  end
                end
              end
            end if query.location.present?
          end
        end if query.valid?

        filter :range, start_date: {lte: Date.current}

        sort { by :id, 'desc' } unless query.keywords.present?
        size document_limit
        from options[:from]
        highlight position_title: {number_of_fragments: 0}
      end

      Rails.logger.info("[Query] #{options.merge(result_count: search.results.total).to_json}")

      search.results.collect do |item|
        {
          id: item.id,
          position_title: (options[:hl] == '1' && item.highlight.present?) ? item.highlight[:position_title][0] : item.position_title,
          organization_name: item.organization_name,
          rate_interval_code: item.rate_interval_code,
          minimum: item.minimum,
          maximum: item.maximum,
          start_date: item.start_date,
          end_date: item.end_date,
          locations: item.locations.collect { |location| "#{location.city}, #{location.state}" }
        }
      end
    end

    def delete_search_index
      search_index.delete
    end

    def search_index
      Tire.index(index_name)
    end

    def import(position_openings)
      Tire.index index_name do
        import position_openings
        refresh
      end

      Rails.logger.info "Processed #{position_openings.size} position openings"
    end
  end
end