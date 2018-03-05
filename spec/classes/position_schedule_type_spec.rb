# frozen_string_literal: true

require 'rails_helper'

describe PositionScheduleType, '.get_code(name)' do
  it 'should lookup position codes' do
    expect(PositionScheduleType.get_code('Full Time')).to eq(1)
    expect(PositionScheduleType.get_code('Part-time')).to eq(2)
    expect(PositionScheduleType.get_code('JobSharing')).to eq(5)
  end

  it 'should return nil for lookup failures' do
    expect(PositionScheduleType.get_code('nope')).to be_nil
  end
end
