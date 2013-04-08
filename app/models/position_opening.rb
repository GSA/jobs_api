class PositionOpening
  include Tire::Model::Search

  index_name("#{Elasticsearch::INDEX_NAME}")

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
              _timestamp: {enabled: true},
              _ttl: {enabled: true},
              properties: {
                type: {type: 'string'},
                source: {type: 'string', index: :not_analyzed},
                tags: {type: 'string', analyzer: 'keyword'},
                external_id: {type: 'integer'},
                position_title: {type: 'string', analyzer: 'custom_analyzer', term_vector: 'with_positions_offsets', store: true},
                organization_id: {type: 'string', analyzer: 'keyword'},
                organization_name: {type: 'string', index: :not_analyzed},
                locations: {type: 'nested', properties: {city: {type: 'string', analyzer: 'simple'}, state: {type: 'string', analyzer: 'keyword'}}},
                start_date: {type: 'date', format: 'YYYY-MM-dd'},
                end_date: {type: 'date', format: 'YYYY-MM-dd'},
                minimum: {type: 'float'},
                maximum: {type: 'float'},
                position_offering_type_code: {type: 'integer'},
                position_schedule_type_code: {type: 'integer'},
                rate_interval_code: {type: 'string', analyzer: 'keyword'},
                id: {type: 'string', index: :not_analyzed, include_in_all: false}
              }
            }
          }
        )
      end
    end

    def search_for(options = {})
      options.reverse_merge!(size: 10, from: 0, sort_by: :_timestamp)
      document_limit = [options[:size].to_i, MAX_RETURNED_DOCUMENTS].min
      source = options[:source]
      tags = options[:tags].present? ? options[:tags].split : nil
      query = Query.new(options[:query], options[:organization_id])
      search = Tire.search index_name do
        query do
          boolean(minimum_number_should_match: 1) do
            must { term :source, source } if source.present?
            must { terms :tags, tags } if tags
            must { match :position_offering_type_code, query.position_offering_type_code } if query.position_offering_type_code.present?
            must { match :position_schedule_type_code, query.position_schedule_type_code } if query.position_schedule_type_code.present?
            should { match :position_title, query.keywords, analyzer: 'custom_analyzer' } if query.keywords.present?
            should do
              nested path: 'locations' do
                query do
                  match 'locations.city', query.keywords, operator: 'AND'
                end
              end
            end if query.keywords.present? && query.location.nil?
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
        end if source.present? || tags || query.valid?

        filter :range, start_date: {lte: Date.current}

        sort { by options[:sort_by], 'desc' } unless query.keywords.present?
        size document_limit
        from options[:from]
        highlight position_title: {number_of_fragments: 0}
      end

      Rails.logger.info("[Query] #{options.merge(result_count: search.results.total).to_json}")

      search.results.collect do |item|
        {
          id: item.id,
          source: item.source,
          external_id: item.external_id,
          position_title: (options[:hl] == '1' && item.highlight.present?) ? item.highlight[:position_title][0] : item.position_title,
          organization_name: item.organization_name,
          rate_interval_code: item.rate_interval_code,
          minimum: item.minimum,
          maximum: item.maximum,
          start_date: item.start_date,
          end_date: item.end_date,
          locations: item.locations.collect { |location| "#{location.city}, #{location.state}" },
          url: url_for_position_opening(item)
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
        import position_openings do |docs|
          docs.each { |doc| doc[:id] = "#{doc[:source]}:#{doc[:external_id]}" }
        end
        refresh
      end

      Rails.logger.info "Processed #{position_openings.size} position openings"
    end

    def get_external_ids_by_source(source)
      from_index = 0
      total = 0
      external_ids = []
      begin
        search = Tire.search index_name do
          query { match :source, source }
          fields %w(external_id)
          sort { by :id }
          from from_index
          size MAX_RETURNED_DOCUMENTS
        end
        external_ids.push(*search.results.map(&:external_id))
        from_index += search.results.count
        total = search.results.total
      end while external_ids.count < total
      external_ids
    end

    def url_for_position_opening(position_opening)
      case position_opening.source
        when 'usajobs'
          "https://www.usajobs.gov/GetJob/ViewDetails/#{position_opening.external_id}"
        when /^ng:/
          agency = position_opening.source.split(':')[1]
          "http://agency.governmentjobs.com/#{agency}/default.cfm?action=viewjob&jobid=#{position_opening.external_id}"
        else nil
      end
    end
  end
end