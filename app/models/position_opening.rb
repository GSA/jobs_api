class PositionOpening
  include Tire::Model::Search

  index_name("#{Elasticsearch::INDEX_NAME}")

  MAX_RETURNED_DOCUMENTS = 100
  SYNONYMS = ["information technology, it, tech, computer", "teacher, teaching", "certified nursing assistant, cna", "rn, registered nurse", "lpn, licensed practical nurse", "lvn, licensed vocational nurse", "pa, physician assistant", "custodial, janitor, custodian", "cys, child youth services", "clerk, clerical", "physician, doctor", "linguist, language", "tv, television", "legal, attorney", "counselor, counseling, therapy, therapist", "green, environment, environmental", "forester, forestry", "technical, technician", "technology, technologist", "electronic, electrical", "architect, architecture", "cypa, child and youth program assistant, childcare", "tso, transportation security officer"].freeze

  class << self

    def create_search_index
      Tire.index index_name do
        create(
          settings: {
            index: {
              analysis: {
                analyzer: { custom_analyzer: { type: 'custom', tokenizer: 'whitespace', filter: %w(standard lowercase synonym snowball) } },
                filter: { synonym: { type: 'synonym', synonyms: SYNONYMS } }
              }
            }
          },
          mappings: {
            position_opening: {
              _timestamp: { enabled: true },
              _ttl: { enabled: true },
              properties: {
                type: { type: 'string' },
                source: { type: 'string', index: :not_analyzed },
                tags: { type: 'string', analyzer: 'keyword' },
                external_id: { type: 'integer' },
                position_title: { type: 'string', analyzer: 'custom_analyzer', term_vector: 'with_positions_offsets', store: true },
                organization_id: { type: 'string', analyzer: 'keyword' },
                organization_name: { type: 'string', index: :not_analyzed },
                locations: {
                  type: 'nested',
                  properties: {
                    city: { type: 'string', analyzer: 'simple' },
                    state: { type: 'string', analyzer: 'keyword' },
                    geo: { type: 'geo_point' } } },
                start_date: { type: 'date', format: 'YYYY-MM-dd' },
                end_date: { type: 'date', format: 'YYYY-MM-dd' },
                minimum: { type: 'float' },
                maximum: { type: 'float' },
                position_offering_type_code: { type: 'integer' },
                position_schedule_type_code: { type: 'integer' },
                rate_interval_code: { type: 'string', analyzer: 'keyword' },
                id: { type: 'string', index: :not_analyzed, include_in_all: false }
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
      tags = options[:tags].present? ? options[:tags].split(/[ ,]/) : nil
      lat, lon = options[:lat_lon].split(',') rescue [nil, nil]
      organization_ids = organization_ids_from_options(options)
      query = Query.new(options[:query], organization_ids)

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
            must do
              boolean do
                should { terms :organization_id, query.organization_terms } if query.organization_terms.present?
                query.organization_prefixes.each do |organization_prefix|
                  should { prefix :organization_id, organization_prefix }
                end if query.organization_prefixes.present?
              end
            end if query.organization_ids.present?
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

        filter :range, start_date: { lte: Date.current }

        if query.keywords.blank?
          if lat.blank? || lon.blank?
            sort { by options[:sort_by], 'desc' }
          else
            options[:sort_by] = 'geo_distance'
            sort do
              by :_geo_distance, {
                'locations.geo' => {
                  lat: lat, lon: lon
                },
                :order => 'asc'
              }
            end
          end
        end
        size document_limit
        from options[:from]
        highlight position_title: { number_of_fragments: 0 }
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
          docs.each do |doc|
            doc[:id] = "#{doc[:source]}:#{doc[:external_id]}"
            doc[:locations].each do |loc|
              normalized_city = loc[:city].sub(' Metro Area', '').sub(/, .*$/, '')
              lat_lon_hash = Geoname.geocode(location: normalized_city, state: loc[:state])
              loc[:geo] = lat_lon_hash if lat_lon_hash.present?
            end if doc[:locations].present?
          end
        end
        refresh
      end

      Rails.logger.info "Imported #{position_openings.size} position openings"
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
      external_ids.flatten
    end

    def url_for_position_opening(position_opening)
      case position_opening.source
        when 'usajobs'
          "https://www.usajobs.gov/GetJob/ViewDetails/#{position_opening.external_id}"
        when /^ng:/
          agency = position_opening.source.split(':')[1]
          "https://agency.governmentjobs.com/#{agency}/default.cfm?action=viewjob&jobid=#{position_opening.external_id}"
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

  end
end