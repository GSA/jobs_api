require 'spec_helper'

describe PositionOfferingType do
  describe '.get_code' do
    it 'should lookup position offering type code' do
      PositionOfferingType.get_code('permanent position').should == 15317
      PositionOfferingType.get_code('Park Ranger seasonal').should == 15322
      PositionOfferingType.get_code('Recent Graduates').should == 15326
      PositionOfferingType.get_code('IT student intern-DHS').should == 15328
      PositionOfferingType.get_code('Professional development internship').should == 15328
    end
  end
end