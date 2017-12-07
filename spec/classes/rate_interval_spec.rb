require 'spec_helper'

describe RateInterval do
  describe '.get_code' do
    it 'should lookup rate interval code' do
      expect(RateInterval.get_code('Hour')).to eq('PH')
      expect(RateInterval.get_code('Hourly')).to eq('PH')
      expect(RateInterval.get_code('Monthly')).to eq('PM')
      expect(RateInterval.get_code('Fee basis')).to eq('FB')
      expect(RateInterval.get_code('Day')).to eq('PD')
      expect(RateInterval.get_code('BiWeekly')).to eq('BW')
    end

    it 'should return nil for lookup failures' do
      expect(RateInterval.get_code('weekly')).to be_nil
    end
  end
end