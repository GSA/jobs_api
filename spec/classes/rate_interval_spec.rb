require 'spec_helper'

describe RateInterval do
  describe '.get_code' do
    it 'should lookup rate interval code' do
      RateInterval.get_code('Hour').should == 'PH'
      RateInterval.get_code('Hourly').should == 'PH'
      RateInterval.get_code('Monthly').should == 'PM'
      RateInterval.get_code('Fee basis').should == 'FB'
      RateInterval.get_code('Day').should == 'PD'
      RateInterval.get_code('BiWeekly').should == 'BW'
    end

    it 'should return nil for lookup failures' do
      RateInterval.get_code('weekly').should be_nil
    end
  end
end