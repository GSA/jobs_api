require 'spec_helper'

describe PositionOfferingType do
  describe '.get_code' do
    it 'should lookup position offering type code' do
      PositionOfferingType.get_code('Permanent position').should == 15317
      PositionOfferingType.get_code('Career Service, Full Time, 40 hrs/week').should == 15317
      PositionOfferingType.get_code('Career Service, Part Time, Std Wkly Hrs Vary').should == 15317
      PositionOfferingType.get_code('Civil Service, Full Time, 40 hrs/week').should == 15317
      PositionOfferingType.get_code('this is permanent').should == 15317
      PositionOfferingType.get_code('FTE - Full-Time').should == 15317
      PositionOfferingType.get_code('PERM FULL TIME').should == 15317

      PositionOfferingType.get_code('Term Limited Temporary, Full Time, 40 hrs/wk').should == 15318
      PositionOfferingType.get_code('Short Term Temporary, Full Time, 40 hrs/wk').should == 15318
      PositionOfferingType.get_code('Temporary - Part-Time').should == 15318
      PositionOfferingType.get_code('Temporary Grant - Full-Time').should == 15318
      PositionOfferingType.get_code('TEMP PART TIME').should == 15318
      PositionOfferingType.get_code('Temporary-Non-Benefit (180 day temp)').should == 15318

      PositionOfferingType.get_code('Sponsored Term Funded Position').should == 15319

      PositionOfferingType.get_code('Temporary Promotion').should == 15321

      PositionOfferingType.get_code('Park Ranger seasonal').should == 15322

      PositionOfferingType.get_code('Recent Graduates').should == 15326

      PositionOfferingType.get_code('IT student intern-DHS').should == 15328
      PositionOfferingType.get_code('Professional development internship').should == 15328

      PositionOfferingType.get_code('Full Time - Non-Permanent').should be_nil
    end
  end
end