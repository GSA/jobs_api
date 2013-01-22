require 'spec_helper'

describe PositionScheduleType, '.get_code(name)' do
  it 'should lookup position codes' do
    PositionScheduleType.get_code('Full Time').should == 1
    PositionScheduleType.get_code('Part-time').should == 2
    PositionScheduleType.get_code('JobSharing').should == 5
  end

  it 'should return nil for lookup failures' do
    PositionScheduleType.get_code('nope').should be_nil
  end
end