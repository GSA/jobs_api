class Query

  JOB_KEYWORD_TOKENS = '(position|job|employment|career)s?'.freeze
  STOPWORDS = 'appl(y|ications?)|for|the|a|and|available|gov(ernment)?|usa|civilian|fed(eral)?|(usajob|opening|posting|description|announcement|listing)s?|(opportunit|vacanc)(y|ies)|search(es)?'.freeze

  attr_accessor :location, :organization_id, :keywords, :position_schedule_type_code, :rate_interval_code

  def initialize(query, organization_id)
    organization_id.upcase! if organization_id.present?
    self.keywords = parse(normalize(query)) if query.present?
    self.organization_id ||= organization_id
  end

  def has_state?
    location.present? && location.state.present?
  end

  def has_city?
    location.present? && location.city.present?
  end

  def valid?
    keywords.present? || location.present? || organization_id.present? || position_schedule_type_code.present? || rate_interval_code.present?
  end

  def organization_format
    organization_id.length == 2 ? :prefix : :term
  end

  private

  def parse(query)
    query.gsub!(/volunteer(ing)? ?/) do
      self.rate_interval_code = 'WC'
      nil
    end
    query.gsub!(/(full|part)([- ])?time ?/) do
      self.position_schedule_type_code = PositionScheduleType.get_code("#{$1}_time")
      nil
    end
    query.gsub!(/ ?(at|with) (.*) in (.*)/) do
      self.organization_id = Agencies.find_organization_id($2)
      self.location = Location.new($3)
      nil
    end
    query.gsub!(/ ?(at|with) (.*)/) do
      self.organization_id = Agencies.find_organization_id($2)
      nil
    end
    query.gsub!(/ ?in (.*)/) do
      self.location = Location.new($1)
      nil
    end
    if self.location.nil? && (state = extract_state(query))
      self.location = Location.new(state)
      query.gsub!(state, '')
    end
    if self.organization_id.nil? && (possible_org = extract_possible_org(query))
      if (self.organization_id = Agencies.find_organization_id(possible_org))
        query.gsub!(possible_org, '')
      end
    end
    query.gsub(/\b#{JOB_KEYWORD_TOKENS}\b/, '').squish
  end

  def normalize(query)
    query.downcase.gsub('.','').gsub(/[^0-9a-z \-]/, ' ').gsub(/\b(#{Date.current.year}|#{STOPWORDS})\b/, ' ').squish
  end

  def extract_possible_org(query)
    leading_phrase_match = query.match(/(.*) #{JOB_KEYWORD_TOKENS}$/)
    return leading_phrase_match[1] if leading_phrase_match.present?
    trailing_phrase_match = query.match(/^#{JOB_KEYWORD_TOKENS} (.*)/)
    trailing_phrase_match[2] if trailing_phrase_match.present?
  end

  def extract_state(query)
    leading_phrase_match = query.match(/(.*) #{JOB_KEYWORD_TOKENS}$/)
    return leading_phrase_match[1] if leading_phrase_match.present? && State.member?(leading_phrase_match[1])
    trailing_phrase_match = query.match(/^#{JOB_KEYWORD_TOKENS} (.*)/)
    trailing_phrase_match[2] if trailing_phrase_match.present? && State.member?(trailing_phrase_match[2])
  end

end