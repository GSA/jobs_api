# frozen_string_literal: true

require 'agencies'

class Query
  JOB_KEYWORD_TOKENS = '(position|job|employment|career|trabajo|puesto|empleo|vacante)s?'
  NON_CAPTURING_JOB_KEYWORD_TOKENS = JOB_KEYWORD_TOKENS.sub('(', '(?:')
  STOPWORDS = 'appl(y|ications?)|for|the|a|and|available|gov(ernment)?|usa|current|civilian|fed(eral)?|(usajob|opening|posting|description|announcement|listing)s?|(opportunit|vacanc)(y|ies)|search(es)?|(posicion|ocupacion|oportunidad|federal)es|gobierno'

  attr_accessor :location, :organization_ids, :keywords, :position_offering_type_code, :position_schedule_type_code, :rate_interval_code

  def initialize(query, organization_ids)
    organization_ids.each(&:upcase!) if organization_ids.present?
    self.keywords = parse(normalize(query)) if query.present?
    self.organization_ids ||= organization_ids
  end

  def state?
    location.present? && location.state.present?
  end

  def city?
    location.present? && location.city.present?
  end

  def valid?
    keywords.present? || location.present? || organization_ids.present? ||
      position_offering_type_code.present? || position_schedule_type_code.present? || rate_interval_code.present?
  end

  def organization_prefixes
    organization_ids.select { |str| str.length == 2 }
  end

  def organization_terms
    organization_ids.select { |str| str.length > 2 }
  end

  private

  def parse(query)
    query.gsub!(/volunteer(ing)? ?/) do
      self.rate_interval_code = 'WC'
      nil
    end
    query.gsub!(/\b(seasonal|intern(ship)?s?)\b/) do
      self.position_offering_type_code = PositionOfferingType.get_code(Regexp.last_match(1).to_s)
      nil
    end
    query.gsub!(/(full|part)([- ])?time ?/) do
      self.position_schedule_type_code = PositionScheduleType.get_code("#{Regexp.last_match(1)}_time")
      nil
    end
    query.gsub!(/ ?(at|with) (.*) in (.*)/) do
      self.organization_ids = ::Agencies.find_organization_ids(Regexp.last_match(2))
      self.location = Location.new(Regexp.last_match(3))
      nil
    end
    query.gsub!(/ ?(at|with) (.*)/) do
      self.organization_ids = ::Agencies.find_organization_ids(Regexp.last_match(2))
      nil
    end
    query.gsub!(/ ?in (.*)/) do
      self.location = Location.new(Regexp.last_match(1))
      nil
    end
    if location.nil? && (location_str = extract_location_string(query))
      self.location = Location.new(location_str)
      query.gsub!(location_str, '')
    end
    if self.organization_ids.nil? && (possible_org = extract_possible_org(query))
      if (self.organization_ids = ::Agencies.find_organization_ids(possible_org))
        query.gsub!(possible_org, '')
      end
    end
    query.gsub(/\b#{JOB_KEYWORD_TOKENS}\b/, '').squish
  end

  def normalize(query)
    query.downcase.delete('.').gsub(/[^0-9a-z \-]/, ' ').gsub(/\b(#{Date.current.year}|#{STOPWORDS})\b/, ' ').squish
  end

  def extract_possible_org(query)
    leading_phrase_match = query.match(/(.*) #{JOB_KEYWORD_TOKENS}$/)
    return leading_phrase_match[1] if leading_phrase_match.present?
    trailing_phrase_match = query.match(/^#{JOB_KEYWORD_TOKENS} (.*)/)
    trailing_phrase_match[2] if trailing_phrase_match.present?
  end

  def extract_location_string(query)
    matches = query.match(/(.*)?\b#{NON_CAPTURING_JOB_KEYWORD_TOKENS}\b(.*)?/)
    return unless matches
    return matches[2].strip if Location.new(matches[2]).state.present?
    return matches[1].strip if Location.new(matches[1]).state.present?
  end
end
