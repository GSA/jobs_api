# frozen_string_literal: true

require 'rails_helper'

describe UsajobsData do
  let(:importer) { UsajobsData.new('doc/sample.xml') }
  let(:far_away) { Date.parse('2022-01-31') }

  describe '#import' do
    it 'should load the PositionOpenings from filename' do
      expect(PositionOpening).to receive(:import) do |position_openings|
        expect(position_openings.length).to eq(3)
        expect(position_openings[0]).to eq(
          type: 'position_opening', source: 'usajobs', external_id: 305_972_200,
          position_title: 'Medical Officer', tags: %w[federal],
          organization_id: 'AF09', organization_name: 'Air Force Personnel Center',
          locations: [{ city: 'Dyess AFB', state: 'TX' }],
          start_date: Date.parse('2011-12-28'), end_date: far_away,
          minimum: 60_274, maximum: 155_500, rate_interval_code: 'PA', position_schedule_type_code: 1, position_offering_type_code: 15_327
        )
        expect(position_openings[1]).to eq(
          type: 'position_opening', source: 'usajobs', external_id: 325_054_900,
          position_title: 'Physician (Surgical Critical Care)', tags: %w[federal],
          organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
          locations: [{ city: 'Charleston', state: 'SC' }],
          start_date: Date.parse('27 Aug 2012'), end_date: far_away,
          minimum: 125_000, maximum: 295_000, rate_interval_code: 'PA', position_schedule_type_code: 2, position_offering_type_code: 15_317
        )
        expect(position_openings[2]).to eq(
          type: 'position_opening', source: 'usajobs', external_id: 327_358_300,
          position_title: 'Student Nurse Technicians', tags: %w[federal],
          organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
          locations: [{ city: 'Odessa', state: 'TX' },
                      { city: 'Pentagon, Arlington', state: 'VA' },
                      { city: 'San Angelo', state: 'TX' },
                      { city: 'Abilene', state: 'TX' }],
          start_date: Date.parse('19 Sep 2012'), end_date: far_away,
          minimum: 17, maximum: 23, rate_interval_code: 'PH', position_schedule_type_code: 2, position_offering_type_code: 15_522
        )
      end
      importer.import
    end

    context 'when records have been somehow marked as inactive/closed/expired' do
      let(:anti_importer) { UsajobsData.new('spec/resources/usajobs/anti_sample.xml') }

      it 'should load the records' do
        expect(PositionOpening).to receive(:import) do |position_openings|
          expect(position_openings.length).to eq(3)
          expect(position_openings[0]).to eq(
            type: 'position_opening', source: 'usajobs', external_id: 305_972_200,
            tags: %w[federal], locations: [{ city: 'Dyess AFB', state: 'TX' }]
          )
          expect(position_openings[1]).to eq(
            type: 'position_opening', source: 'usajobs', external_id: 325_054_900,
            tags: %w[federal], locations: [{ city: 'Charleston', state: 'SC' }]
          )
          expect(position_openings[2]).to eq(
            type: 'position_opening', source: 'usajobs', external_id: 327_358_300,
            tags: %w[federal], locations: [{ city: 'Odessa', state: 'TX' },
                                           { city: 'Pentagon, Arlington', state: 'VA' },
                                           { city: 'San Angelo', state: 'TX' },
                                           { city: 'Abilene', state: 'TX' }]
          )
        end
        anti_importer.import
      end
    end

    context 'when location is invalid/empty' do
      let(:bad_location_importer) { UsajobsData.new('spec/resources/usajobs/bad_locations.xml') }

      it 'should ignore the location' do
        expect(PositionOpening).to receive(:import) do |position_openings|
          expect(position_openings.length).to eq(2)
          expect(position_openings[0]).to eq(
            type: 'position_opening', source: 'usajobs', external_id: 305_972_200, position_title: 'Medical Officer',
            organization_id: 'AF09', organization_name: 'Air Force Personnel Center', tags: %w[federal],
            locations: [{ city: 'Fulton', state: 'MD' }],
            start_date: Date.parse('28 Dec 2011'), end_date: far_away,
            minimum: 60_274, maximum: 155_500, rate_interval_code: 'PA', position_schedule_type_code: 1, position_offering_type_code: 15_327
          )
          expect(position_openings[1]).to eq(
            type: 'position_opening', source: 'usajobs', external_id: 325_054_900, locations: [], tags: %w[federal]
          )
        end
        bad_location_importer.import
      end
    end

    context 'when too many locations are present for job (typical of recruiting announcements)' do
      let(:recruiting_importer) { UsajobsData.new('spec/resources/usajobs/recruiting_sample.xml') }

      it 'should load the records with a ttl of 1s and empty locations array' do
        expect(PositionOpening).to receive(:import) do |position_openings|
          expect(position_openings.length).to eq(1)
          expect(position_openings[0]).to eq(
            type: 'position_opening', source: 'usajobs', external_id: 327_358_300,
            tags: %w[federal], locations: []
          )
        end
        recruiting_importer.import
      end
    end
  end

  describe '#normalize_location(location_str)' do
    context 'when it looks like city-comma-the long form of a state name' do
      it 'should map it to the abbreviation' do
        expect(importer.normalize_location('Vancouver, Washington')).to eq('Vancouver, WA')
      end
    end

    context 'when it is some Puerto Rico variant' do
      it 'should normalize to city, PR' do
        location_strs = ['City Puerto Rico', 'City, PR Puerto Rico']
        location_strs.each { |location_str| expect(importer.normalize_location(location_str)).to eq('City, PR') }
      end
    end

    context 'when it is some Guam variant' do
      it 'should normalize to city, GQ' do
        location_strs = ['City Guam', 'City, GQ Guam']
        location_strs.each { |location_str| expect(importer.normalize_location(location_str)).to eq('City, GQ') }
      end
    end

    context 'when it is some basic DC variant' do
      it 'should normalize to Washington, DC' do
        location_strs = ['Washington DC, DC United States',
                         'Washington, DC, US',
                         'Washington DC, DC',
                         'District Of Columbia County, DC, US',
                         'District of Columbia, DC United States',
                         'Dist. of Columbia, DC United States',
                         'Dist of Columbia, DC United States',
                         'Washington, Dist of Columbia',
                         'Washington, District of Columbia',
                         'Washington, Dist. of Columbia',
                         'Washington, DC',
                         'Washington, DC, Dist of Columbia',
                         'Washington DC',
                         'Washington D.C.',
                         'Washington DC, US',
                         'District Of Columbia, US']
        location_strs.each { |location_str| expect(importer.normalize_location(location_str)).to eq('Washington, DC') }
      end
    end

    context 'when it is some DC Metro variant' do
      it 'should normalize to Washington Metro Area, DC' do
        location_strs = ['Washington DC Metro Area, DC United States', 'Washington DC Metro Area, DC, US',
                         'Washington DC Metro Area, DC']
        location_strs.each { |location_str| expect(importer.normalize_location(location_str)).to eq('Washington Metro Area, DC') }
      end
    end

    context 'when it is some Central Office DC variant' do
      it 'should normalize to Central Office, Washington, DC' do
        location_strs = ['Central Office, Washington DC, US', 'Central Office, Washington, DC',
                         'Central Office, Washington DC']
        location_strs.each { |location_str| expect(importer.normalize_location(location_str)).to eq('Central Office, Washington, DC') }
      end
    end

    context 'when it contains parens' do
      it 'should remove them' do
        expect(importer.normalize_location('Suburb, (Suitland, MD)')).to eq('Suburb, Suitland, MD')
      end
    end

    context 'when it refers to the Arizona Strip' do
      it 'should strip that out' do
        expect(importer.normalize_location('Saint George, UT, US Arizona Strip')).to eq('Saint George, UT')
      end
    end

    context 'when there is no match' do
      it 'should just return the string unchanged' do
        expect(importer.normalize_location('FAA Air Traffic Control Locations')).to eq('FAA Air Traffic Control Locations')
      end
    end
  end
end
