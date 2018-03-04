# frozen_string_literal: true

class Location
  attr_accessor :city, :state

  def initialize(loc)
    location = loc.dup
    if (response = detect_state(location))
      self.state = response.last
      location.sub!(/ ?#{response.first}$/, '')
    end
    self.city = location.strip
  end

  private

  def detect_state(location)
    tokens = location.split
    max_state_word_count = [4, tokens.size].max
    max_state_word_count.times do |idx|
      candidate = tokens.last(idx + 1).join(' ')
      return [candidate, State.normalize(candidate)] if State.member? candidate
    end
    nil
  end
end
