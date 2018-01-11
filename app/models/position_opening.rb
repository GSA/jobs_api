require 'active_model'
require 'elasticsearch/dsl'

class PositionOpening
  include ActiveModel::Model
  include Elasticsearch::Model
  include Elasticsearch::DSL

  INDEX_NAME = "#{Elasticsearch::INDEX_NAME}".freeze

  MAX_RETURNED_DOCUMENTS = 100.freeze

  SYNONYMS = [
    "architect, architecture",
    "certified nursing assistant, cna",
    "clerk, clerical",
    "counselor, counseling, therapy, therapist",
    "custodial, janitor, custodian",
    "cypa, child and youth program assistant, childcare",
    "cys, child youth services",
    "electronic, electrical",
    "forester, forestry",
    "green, environment, environmental",
    "information technology, it, tech, computer",
    "linguist, language",
    "legal, attorney",
    "lpn, licensed practical nurse",
    "lvn, licensed vocational nurse",
    "pa, physician assistant",
    "physician, doctor",
    "rn, registered nurse",
    "teacher, teaching",
    "technical, technician",
    "technology, technologist",
    "tso, transportation security officer",
    "tv, television"
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
          filter: %w(standard lowercase synonym snowball)
        }
      }
    }
  }

  settings index: SETTINGS do
    mappings dynamic: 'false' do
      indexes :type, type: 'keyword'
      indexes :source, type: 'keyword'
      indexes :tags, type: 'text', analyzer: 'keyword'
      indexes :external_id, type: 'integer', store: true
      indexes :position_title, type: 'text', analyzer: 'custom_analyzer', term_vector: 'with_positions_offsets', store: true
      indexes :organization_id, type: 'text', analyzer: 'keyword'
      indexes :organization_name, type: 'keyword', index: false

      indexes :locations, type: 'nested' do
        indexes :city, type: 'text', analyzer: 'simple'
        indexes :state, type: 'text', analyzer: 'keyword'
        indexes :geo, type: 'geo_point'
      end

      indexes :start_date, type: 'date', format: 'YYYY-MM-dd'
      indexes :end_date, type: 'date', format: 'YYYY-MM-dd'
      indexes :minimum, type: 'float'
      indexes :maximum, type: 'float'
      indexes :position_offering_type_code, type: 'integer'
      indexes :position_schedule_type_code, type: 'integer'
      indexes :rate_interval_code, type: 'text', analyzer: 'keyword'
      indexes :id, type: 'keyword', index: false
      indexes :timestamp, type: 'date', null_value: 'NULL'
    end
  end

  class << self

    def client
      @client ||= PositionOpening.__elasticsearch__.client
    end

    def create_search_index
      client.indices.create(
        index: INDEX_NAME,
        body: { settings: settings.to_hash, mappings: mappings.to_hash }
      )
    end

    def search_for(options = {})
      options.reverse_merge!(size: 10, from: 0)
      document_limit = [options[:size].to_i, MAX_RETURNED_DOCUMENTS].min
      source = options[:source]
      sort_by = options[:sort_by] || :timestamp
      tags = options[:tags].present? ? options[:tags].split(/[ ,]/) : nil
      lat, lon = options[:lat_lon].split(',') rescue [nil, nil]
      organization_ids = organization_ids_from_options(options)
      query = Query.new(options[:query], organization_ids)

      definition = Elasticsearch::DSL::Search.search do
        query do
          bool do
            filter do
              range :start_date do
                lte Date.current
              end
            end

            must { term source: source } if source.present?
            must { terms tags: tags } if tags
            must do
              match :position_offering_type_code do
                query query.position_offering_type_code
              end
            end if query.position_offering_type_code.present?

            must do
              match :position_schedule_type_code do
                query query.position_schedule_type_code
              end
            end if query.position_schedule_type_code.present?

            should do
              match :position_title do
                query query.keywords
                analyzer 'custom_analyzer'
              end
            end if query.keywords.present?
            should do
              nested do
                path 'locations'
                query do
                  match 'locations.city' do
                    query query.keywords
                    operator 'and'
                  end
                end
              end
            end if query.keywords.present? && query.location.nil?

            must do
              match :rate_interval_code do
                query query.rate_interval_code
              end
            end if query.rate_interval_code.present?

            must do
              bool do
                should { terms organization_id: query.organization_terms } if query.organization_terms.present?
                if query.organization_prefixes.present?
                  query.organization_prefixes.each do |prefix|
                    should { prefix organization_id: prefix }
                  end
                end
              end
            end if query.organization_ids.present?

            must do
              nested do
                path 'locations'
                query do
                  bool do
                    must { term 'locations.state': query.location.state } if query.has_state?
                    must do
                      match 'locations.city' do
                        query query.location.city
                        operator 'and'
                      end
                    end if query.has_city?
                  end
                end
              end
            end if query.location.present?

            minimum_should_match '0<1'
          end
        end

        sort do
          if query.keywords.blank?
            if lat.blank? || lon.blank?
              by "#{sort_by}", order: 'desc'
            else
              by({
                _geo_distance: {
                  'locations.geo': { lat: lat.to_f, lon: lon.to_f },
                  order: 'asc',
                  nested_path: 'locations'
                }
              })
            end
          else
            by "#{sort_by}", order: 'desc'
          end
        end

        highlight { field :position_title, number_of_fragments: 0 }
        size document_limit
        from options[:from]
      end.to_hash

      search_results = __elasticsearch__.search(definition, index: INDEX_NAME)

      Rails.logger.info("[Query] #{options.merge(result_count: search_results.results.total).to_json}")

      search_results.results.collect do |item|
        {
          id: item.id,
          source: item.source,
          external_id: item.external_id,
          position_title: (options[:hl] == '1' && item.try(:highlight).present?) ? item.highlight[:position_title][0] : item.position_title,
          organization_name: item.try(:organization_name),
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
      client.indices.delete index: INDEX_NAME rescue nil
    end

    def search_index_exists?
      client.indices.exists? index: INDEX_NAME
    end

    def import(position_openings)
      position_openings.each do |opening|
        data = opening.each_with_object({timestamp: DateTime.current}) do |(key, value), data|
          data[key] =
            case key
            when :locations
              value.map do |v|
                {
                  city: normalized_city(v[:city]),
                  state: v[:state],
                  geo: v[:geo] || find_geoname(v[:city], v[:state])
                }
              end
            else
              value
            end
        end

        id = "#{opening[:source]}:#{opening[:external_id]}"
        client.index(
          index: INDEX_NAME,
          type: 'position_opening',
          id: id,
          body: data.merge!(id: id)
        )
      end

      __elasticsearch__.refresh_index! index: INDEX_NAME

      Rails.logger.info "Imported #{position_openings.size} position openings"
    end

    def get_external_ids_by_source(source)
      from_index = 0
      total = 0
      external_ids = []
      begin
        search_definition = {
          query: { match: { source: { query: source }}},
          stored_fields: %w(external_id),
          _source: true
        }

        search_definition[:size] = MAX_RETURNED_DOCUMENTS
        search_definition[:from] = from_index
        search_definition[:sort] = ['external_id']

        search = __elasticsearch__.search(search_definition, index: INDEX_NAME)
        external_ids.push(*search.results.map(&:external_id))
        from_index += search.results.count
        total = search.results.total
      end while external_ids.count < total
      external_ids.flatten
    end

    def delete_expired_docs
      query = Elasticsearch::DSL::Search.search do
        query do
          bool do
            filter do
              bool do
                should do
                  range :end_date do
                    lte Date.current
                  end
                end

                should do
                  bool do
                    must_not do
                      bool do
                        must do
                          exists { field 'end_date' }
                        end
                        must do
                          exists { field 'start_date' }
                        end
                      end
                    end
                  end
                end

              end
            end
          end
        end
      end

      client.delete_by_query(body: query.to_hash, index: INDEX_NAME)
      __elasticsearch__.refresh_index! index: INDEX_NAME
    end

    def url_for_position_opening(position_opening)
      case position_opening.source
        when 'usajobs'
          "https://www.usajobs.gov/GetJob/ViewDetails/#{position_opening.external_id}"
        when /^ng:/
          agency = position_opening.source.split(':')[1]
          "http://agency.governmentjobs.com/#{agency}/default.cfm?action=viewjob&jobid=#{position_opening.external_id}"
        else
          nil
      end
    end

    def organization_ids_from_options(options)
      organization_ids = []
      organization_ids << options[:organization_id] if options[:organization_id].present?
      organization_ids.concat options[:organization_ids].split(',') if options[:organization_ids].present?
      organization_ids
    end

    def find_geoname(location, state)
      Geoname.geocode(location: normalized_city(location), state: state)
    end

    def normalized_city(city)
      city.sub(' Metro Area', '').sub(/, .*$/, '')
    end
  end
end
