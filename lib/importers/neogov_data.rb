class NeogovData
  XPATHS = {
      organization_name: '/rss/channel/title',
      item: '//item',
      pubdate: './pubdate',
      start_date: './joblisting:advertiseFromDate',
      end_date: './joblisting:advertiseToDateTime',
      end_date_utc: './joblisting:advertiseToDateTimeUTC',
      position_title: './title',
      id: './joblisting:jobId',
      location: './joblisting:location',
      state: './joblisting:state',
      job_type: './joblisting:jobType',
      minimum: './joblisting:minimumSalary',
      maximum: './joblisting:maximumSalary',
      salary_interval: './joblisting:salaryInterval'
  }.freeze

  HOST = 'agency.governmentjobs.com'.freeze
  PATH = '/jobfeed.cfm?agency='.freeze
  USER_AGENT = 'USASearch Jobs API'.freeze

  INVALID_LOCATION_REGEX = /\b(various|locations?)\b/i

  ADVERTISE_DATE_FORMAT = '%a, %d %b %Y'.freeze
  ADVERTISE_DATETIME_FORMAT = '%a, %d %b %Y %H:%M:%S'.freeze

  def initialize(agency, tags, organization_id, organization_name = nil)
    @agency = agency
    @source = "ng:#{agency}"
    @tags = tags.present? ? tags.split : []
    @organization_id = organization_id
    @organization_name = organization_name
  end

  def import
    doc = Nokogiri::XML(fetch_jobs_rss)
    @organization_name = doc.xpath(XPATHS[:organization_name]).inner_text.squish if @organization_name.blank?
    position_openings = doc.xpath(XPATHS[:item]).map { |job_xml| process_job(job_xml) }.compact
    updated_external_ids = position_openings.map { |item| item[:external_id] }

    existing_external_ids = PositionOpening.get_external_ids_by_source(@source)
    expired_ids = existing_external_ids - updated_external_ids
    expired_openings = expired_ids.collect do |expired_id|
      {type: 'position_opening', source: @source, external_id: expired_id, _ttl: '1s'}
    end
    position_openings.push(*expired_openings)
    PositionOpening.import position_openings
  end

  def fetch_jobs_rss
    http = Net::HTTP.new(HOST)
    req = Net::HTTP::Get.new("#{PATH}#{@agency}", {'User-Agent' => USER_AGENT})
    response = http.request(req)
    response.body
  end

  def process_job(job_xml)
    end_date_str = job_xml.xpath(XPATHS[:end_date]).inner_text.squish
    pubdate = DateTime.parse(job_xml.xpath(XPATHS[:pubdate]).inner_text.squish)

    now = DateTime.current.freeze

    is_continuous = end_date_str =~ /^continuous$/i
    if is_continuous
      end_datetime_utc = now + 7
      end_date = end_datetime_utc.to_date
    else
      end_datetime_utc_str = job_xml.xpath(XPATHS[:end_date_utc]).inner_text.squish
      end_datetime_utc = DateTime.strptime(end_datetime_utc_str, ADVERTISE_DATETIME_FORMAT) rescue nil
      end_date = Date.strptime(end_date_str, ADVERTISE_DATETIME_FORMAT) rescue nil
    end

    start_date = Date.strptime(job_xml.xpath(XPATHS[:start_date]).inner_text.strip, ADVERTISE_DATE_FORMAT) rescue nil

    seconds_remaining = [0, end_datetime_utc.to_i - pubdate.to_i].max
    seconds_remaining = 0 if start_date.nil? || end_date.nil? || (start_date > end_date)
    seconds_remaining = 0 if now > end_datetime_utc

    entry = {type: 'position_opening',
             source: @source,
             organization_id: @organization_id,
             organization_name: @organization_name,
             tags: @tags}
    entry[:external_id] = job_xml.xpath(XPATHS[:id]).inner_text.to_i
    entry[:locations] = process_location_and_state(job_xml.xpath(XPATHS[:location]).inner_text,
                                                   job_xml.xpath(XPATHS[:state]).inner_text)

    if seconds_remaining.zero? || entry[:locations].blank?
      entry[:_ttl] = '1s'
      return entry
    end

    entry[:_timestamp] = pubdate.iso8601
    entry[:_ttl] = "#{seconds_remaining}s"
    entry[:position_title] = job_xml.xpath(XPATHS[:position_title]).inner_text.squish
    entry[:start_date] = start_date
    entry[:end_date] = is_continuous ? nil : end_date
    entry[:minimum] = process_salary(job_xml.xpath(XPATHS[:minimum]).inner_text)
    entry[:maximum] = process_salary(job_xml.xpath(XPATHS[:maximum]).inner_text)
    entry[:rate_interval_code] = process_salary_interval(job_xml.xpath(XPATHS[:salary_interval]).inner_text)
    entry.merge!(process_job_type(job_xml.xpath(XPATHS[:job_type]).inner_text))

    entry
  end

  def process_location_and_state(city_str, state_str)
    city = city_str =~ INVALID_LOCATION_REGEX ? nil : remove_trailing_state_zip(strip_prefix(city_str)).rpartition(',')[2].to_s.squish
    state_name = state_str.squish
    state = State.member?(state_name) ? State.normalize(state_name) : nil

    city.present? && state.present? ? [{city: city, state: state}] : []
  end

  def process_salary_interval(salary_interval_str)
    RateInterval.get_code(salary_interval_str.squish)
  end

  def process_job_type(job_type_str)
    job_type_hash = {}
    job_type = job_type_str.downcase.squish

    job_type_hash[:position_offering_type_code] = PositionOfferingType.get_code(job_type)
    job_type_hash[:position_schedule_type_code] = job_type.match(/\b(full|part)([- ])?time\b/) do |m|
      PositionScheduleType.get_code(m[0])
    end

    job_type_hash
  end

  def process_salary(salary_str)
    salary = salary_str.strip
    salary.to_f.round(2) if salary =~ /^\d+\.?\d*$/
  end

  private

  def remove_trailing_state_zip(city_str)
    city_str.sub(/, ?[A-Z]{2} ?\d{5}?-?(\d{4})?$/,'')
  end

  def strip_prefix(city_str)
    city_str.sub(/^[^a-zA-Z]+/,'')
  end
end