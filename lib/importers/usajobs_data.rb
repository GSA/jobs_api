class UsajobsData
  CATCHALL_THRESHOLD = 20
  SOURCE = 'usajobs'.freeze
  XPATHS = {
    opening: '//xmlns:PositionOpening',
    start_date: 'xmlns:PositionProfile/xmlns:PositionPeriod/xmlns:StartDate/xmlns:FormattedDateTime',
    end_date: 'xmlns:PositionProfile/xmlns:PositionPeriod/xmlns:EndDate/xmlns:FormattedDateTime',
    position_title: 'xmlns:PositionProfile/xmlns:PositionTitle',
    id: 'xmlns:DocumentID',
    status_code: 'xmlns:PositionOpeningStatusCode',
    organization_id: 'xmlns:PositionProfile/xmlns:PositionOrganization/xmlns:OrganizationIdentifiers/xmlns:OrganizationID',
    organization_name: 'xmlns:PositionProfile/xmlns:PositionOrganization/xmlns:OrganizationIdentifiers/xmlns:OrganizationName',
    locations: 'xmlns:PositionProfile/xmlns:PositionLocation/xmlns:LocationName',
    position_schedule_type_code: 'xmlns:PositionProfile/xmlns:PositionScheduleTypeCode',
    position_offering_type_code: 'xmlns:PositionProfile/xmlns:PositionOfferingTypeCode',
    minimum: 'xmlns:PositionProfile/xmlns:OfferedRemunerationPackage/xmlns:RemunerationRange/xmlns:RemunerationMinimumAmount',
    maximum: 'xmlns:PositionProfile/xmlns:OfferedRemunerationPackage/xmlns:RemunerationRange/xmlns:RemunerationMaximumAmount',
    rate_interval_code: 'xmlns:PositionProfile/xmlns:OfferedRemunerationPackage/xmlns:RemunerationRange/xmlns:RemunerationRateIntervalCode'
  }.freeze

  def initialize(filename)
    @filename = filename
  end

  def import
    doc = Nokogiri::XML(File.open(@filename))
    position_openings = doc.xpath(XPATHS[:opening]).map { |job_xml| process_job(job_xml) }
    PositionOpening.import position_openings
  end

  def process_job(job_xml)
    end_date = Date.parse(job_xml.xpath(XPATHS[:end_date]).inner_text)
    start_date = Date.parse(job_xml.xpath(XPATHS[:start_date]).inner_text)
    days_remaining = (end_date - Date.current).to_i
    inactive = job_xml.xpath(XPATHS[:status_code]).inner_text != 'Active'
    days_remaining = 0 if days_remaining < 0 || start_date > end_date || inactive
    entry = {type: 'position_opening', source: SOURCE, tags: %w(federal)}
    entry[:external_id] = job_xml.xpath(XPATHS[:id]).inner_text.to_i
    entry[:locations] = process_locations(job_xml)
    entry[:locations] = [] if entry[:locations].size >= CATCHALL_THRESHOLD
    # entry[:_ttl] = (days_remaining.zero? || entry[:locations].empty?) ? '1s' : "#{days_remaining}d"
    unless entry[:locations].empty? || days_remaining.zero?
      entry[:position_title] = job_xml.xpath(XPATHS[:position_title]).inner_text.strip
      entry[:organization_id] = job_xml.xpath(XPATHS[:organization_id]).inner_text.strip.upcase
      entry[:organization_name] = job_xml.xpath(XPATHS[:organization_name]).inner_text.strip
      entry[:start_date] = start_date
      entry[:end_date] = end_date
      entry[:minimum] = job_xml.xpath(XPATHS[:minimum]).inner_text.to_i
      entry[:maximum] = job_xml.xpath(XPATHS[:maximum]).inner_text.to_i
      entry[:rate_interval_code] = job_xml.xpath(XPATHS[:rate_interval_code]).inner_text.strip.upcase
      entry[:position_schedule_type_code] = job_xml.xpath(XPATHS[:position_schedule_type_code]).inner_text.split('-').first.to_i
      entry[:position_offering_type_code] = job_xml.xpath(XPATHS[:position_offering_type_code]).inner_text.split('-').first.to_i
    end
    entry
  end

  def process_locations(job_xml)
    job_xml.xpath(XPATHS[:locations]).collect do |location_name_xml|
      location_str = location_name_xml.inner_text.strip
      normalized_location_str = normalize_location(location_str)
      cities_comma_state = normalized_location_str.rpartition(',')
      city, state = cities_comma_state.first.strip, cities_comma_state.last.strip
      {city: city, state: state} if state.length == 2
    end.compact
  end

  def normalize_location(location_str)
    location_str.gsub!(/[()]/, '')
    location_str.sub!(/ Arizona Strip$/i, '')
    location_str.sub!(/ ?(United States|, US)$/i, '')
    location_str.sub!(/(, GQ)? Guam$/i, ', GQ')
    location_str.sub!(/(, PR)? Puerto Rico$/i, ', PR')
    location_str.sub!(/^(Dist(\.|rict)? of Columbia)$/i, 'Washington, DC')
    location_str.sub!(/(Dist(\.|rict)? of Columbia|D.C.)$/i, 'DC')
    location_str.sub!(/ DC, DC/i, ' DC')
    location_str.sub!(/^Dist(\.|rict)? of Columbia( County)?/i, 'Washington')
    location_str.sub!(/^Washington DC Metro Area/i, 'Washington Metro Area')
    location_str.sub!(/Washington DC$/i, 'Washington, DC')
    abbreviate_state_name(location_str)
  end

  def abbreviate_state_name(location_str)
    state_name = location_str.rpartition(',').last.strip
    if State.member?(state_name)
      abbreviation = State.normalize(state_name)
      if abbreviation != state_name
        return location_str.sub(/#{state_name}/, abbreviation)
      end
    end
    location_str
  end
end
