# frozen_string_literal: true

require 'rails_helper'

describe PositionOfferingType do
  describe '.get_code' do
    it 'should lookup position offering type code' do
      expect(PositionOfferingType.get_code('Permanent position')).to eq(15_317)
      expect(PositionOfferingType.get_code('Career Service, Full Time, 40 hrs/week')).to eq(15_317)
      expect(PositionOfferingType.get_code('Career Service, Part Time, Std Wkly Hrs Vary')).to eq(15_317)
      expect(PositionOfferingType.get_code('Civil Service, Full Time, 40 hrs/week')).to eq(15_317)
      expect(PositionOfferingType.get_code('this is permanent')).to eq(15_317)
      expect(PositionOfferingType.get_code('FTE - Full-Time')).to eq(15_317)
      expect(PositionOfferingType.get_code('PERM FULL TIME')).to eq(15_317)

      expect(PositionOfferingType.get_code('Term Limited Temporary, Full Time, 40 hrs/wk')).to eq(15_318)
      expect(PositionOfferingType.get_code('Short Term Temporary, Full Time, 40 hrs/wk')).to eq(15_318)
      expect(PositionOfferingType.get_code('Temporary - Part-Time')).to eq(15_318)
      expect(PositionOfferingType.get_code('Temporary Grant - Full-Time')).to eq(15_318)
      expect(PositionOfferingType.get_code('TEMP PART TIME')).to eq(15_318)
      expect(PositionOfferingType.get_code('Temporary-Non-Benefit (180 day temp)')).to eq(15_318)

      expect(PositionOfferingType.get_code('Sponsored Term Funded Position')).to eq(15_319)

      expect(PositionOfferingType.get_code('Temporary Promotion')).to eq(15_321)

      expect(PositionOfferingType.get_code('Park Ranger seasonal')).to eq(15_322)

      expect(PositionOfferingType.get_code('Recent Graduates')).to eq(15_326)

      expect(PositionOfferingType.get_code('IT student intern-DHS')).to eq(15_328)
      expect(PositionOfferingType.get_code('Professional development internship')).to eq(15_328)

      expect(PositionOfferingType.get_code('Full Time - Non-Permanent')).to be_nil
    end
  end
end
