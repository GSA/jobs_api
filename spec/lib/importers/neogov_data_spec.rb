# frozen_string_literal: true

require 'rails_helper'

describe NeogovData do
  let(:importer) { NeogovData.new('michigan', 'state', 'USMI') }

  describe '#import' do
    let!(:current_datetime) { DateTime.current.freeze }
    let!(:current) { current_datetime.to_date.freeze }
    let(:far_away) { Date.parse('2022-01-31') }
    # let(:continuous_ttl) { "#{(current_datetime + 7).to_i - DateTime.parse('2012-03-12 10:16:56.14').to_datetime.to_i}s" }

    before { allow(DateTime).to receive(:current).and_return(current_datetime) }

    context 'when RSS contains valid jobs' do
      before do
        allow(importer).to receive(:fetch_jobs_rss).and_return File.open('doc/neogov_sample.rss')
      end

      it 'should load the PositionOpenings from filename' do
        expect(PositionOpening).to receive(:get_external_ids_by_source).with('ng:michigan').and_return([])
        expect(PositionOpening).to receive(:import) do |position_openings|
          expect(position_openings.length).to eq(5)

          expect(position_openings[0]).to eq(
            type: 'position_opening', source: 'ng:michigan',
            organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w[state],
            timestamp: '2013-04-12T15:52:34+00:00', external_id: 634_789,
            locations: [{ city: 'Lansing', state: 'MI' }],
            position_title: 'Professional Development and Training Intern-DHS',
            start_date: Date.parse('2013-04-12'), end_date: far_away, minimum: nil, maximum: nil,
            rate_interval_code: 'PH', position_offering_type_code: 15_328, position_schedule_type_code: nil
          )

          expect(position_openings[1]).to eq(
            type: 'position_opening', source: 'ng:michigan',
            organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w[state],
            timestamp: '2013-04-08T15:15:21+00:00', external_id: 631_517,
            locations: [{ city: 'Lansing', state: 'MI' }],
            position_title: 'MEDC Corporate - Business Attraction Manager',
            start_date: Date.parse('2013-04-08'), end_date: far_away, minimum: 59_334.0, maximum: 77_066.0,
            rate_interval_code: 'PA', position_offering_type_code: 15_317, position_schedule_type_code: 1
          )

          expect(position_openings[2]).to eq(
            type: 'position_opening', source: 'ng:michigan',
            organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w[state],
            timestamp: '2012-03-12T10:16:56+00:00', external_id: 282_662,
            locations: [{ city: 'Freeland', state: 'MI' }], position_title: 'Dentist-A',
            start_date: Date.parse('2011-09-23'), end_date: nil, minimum: 37.33, maximum: 51.66,
            rate_interval_code: 'PH', position_offering_type_code: 15_317, position_schedule_type_code: 2
          )

          expect(position_openings[3]).to eq(
            type: 'position_opening', source: 'ng:michigan',
            organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w[state],
            timestamp: '2010-08-10T16:07:30+00:00', external_id: 234_175,
            locations: [{ city: 'Munising', state: 'MI' }], position_title: 'Registered Nurse Non-Career',
            start_date: Date.parse('2010-06-08'), end_date: far_away, minimum: 28.37, maximum: 38.87,
            rate_interval_code: 'PH', position_offering_type_code: nil, position_schedule_type_code: nil
          )

          expect(position_openings[4]).to eq(
            type: 'position_opening', source: 'ng:michigan',
            organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w[state],
            external_id: 234_176, locations: [{ city: 'Munising', state: 'MI' }]
          )
        end
        importer.import
      end
    end

    context 'when position openings exist that are no longer in the feed' do
      let(:less_entries_importer) { NeogovData.new('michigan', 'state', 'USMI') }

      before do
        allow(less_entries_importer).to receive(:fetch_jobs_rss).and_return File.open('spec/resources/neogov/less_items.rss')
      end

      it 'should expire them' do
        expect(PositionOpening).to receive(:get_external_ids_by_source).with('ng:michigan').and_return([282_662])
        expect(PositionOpening).to receive(:import) do |position_openings|
          expect(position_openings.length).to eq(3)

          expect(position_openings[0]).to eq(
            type: 'position_opening', source: 'ng:michigan',
            organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w[state],
            timestamp: '2013-04-12T15:52:34+00:00', external_id: 634_789,
            locations: [{ city: 'Lansing', state: 'MI' }],
            position_title: 'Professional Development and Training Intern-DHS',
            start_date: Date.parse('2013-04-12'), end_date: far_away, minimum: nil, maximum: nil,
            rate_interval_code: 'PH', position_offering_type_code: 15_328, position_schedule_type_code: nil
          )

          expect(position_openings[1]).to eq(
            type: 'position_opening', source: 'ng:michigan',
            organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w[state],
            timestamp: '2013-04-08T15:15:21+00:00', external_id: 631_517,
            locations: [{ city: 'Lansing', state: 'MI' }],
            position_title: 'MEDC Corporate - Business Attraction Manager',
            start_date: Date.parse('2013-04-08'), end_date: far_away, minimum: 59_334.0, maximum: 77_066.0,
            rate_interval_code: 'PA', position_offering_type_code: 15_317, position_schedule_type_code: 1
          )

          expect(position_openings[2]).to eq(
            type: 'position_opening', source: 'ng:michigan', external_id: 282_662
          )
        end
        less_entries_importer.import
      end
    end

    context 'when invalid/expired position openings are in the feed' do
      let(:expired_importer) { NeogovData.new('michigan', 'state', 'USMI') }

      before do
        allow(expired_importer).to receive(:fetch_jobs_rss).and_return File.open('spec/resources/neogov/expired.rss')
      end

      it 'should still load the data' do
        expect(PositionOpening).to receive(:get_external_ids_by_source).with('ng:michigan').and_return([])
        expect(PositionOpening).to receive(:import) do |position_openings|
          expect(position_openings.length).to eq(1)

          expect(position_openings[0]).to eq(
            {type: 'position_opening', source: 'ng:michigan',
             organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w(state),
             external_id: 282662, locations: [{city: 'Freeland', state: 'MI'}]}
          )
        end
        expired_importer.import
      end
    end

    context 'when the city or state is invalid' do
      let(:bad_location_importer) { NeogovData.new('michigan', 'state', 'USMI') }

      before do
        allow(bad_location_importer).to receive(:fetch_jobs_rss).and_return File.open('spec/resources/neogov/bad_locations.rss')
      end

      it 'should set location to an empty array' do
        expect(PositionOpening).to receive(:get_external_ids_by_source).with('ng:michigan').and_return([])
        expect(PositionOpening).to receive(:import) do |position_openings|
          expect(position_openings.length).to eq(1)

          expect(position_openings[0]).to eq(
            type: 'position_opening', source: 'ng:michigan',
            organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w[state],
            external_id: 386_302, locations: []
          )
        end
        bad_location_importer.import
      end
    end

    context 'when organization_name is defined' do
      let(:org_name_importer) { NeogovData.new('michigan', 'state', 'USMI', 'State of Michigan') }

      before do
        allow(org_name_importer).to receive(:fetch_jobs_rss).and_return File.open('doc/neogov_sample.rss')
      end

      it 'should use the predefined organization name' do
        expect(PositionOpening).to receive(:get_external_ids_by_source).with('ng:michigan').and_return([])
        expect(PositionOpening).to receive(:import) do |position_openings|
          expect(position_openings.length).to eq(5)
          expect(position_openings.map { |po| po[:organization_name] }.uniq).to eq(['State of Michigan'])
        end
        org_name_importer.import
      end
    end
  end

  describe '#process_location_and_state' do
    it 'should convert state name to state abbreviation' do
      expect(importer.process_location_and_state('Lansing', 'Michigan')).to eq([{ city: 'Lansing', state: 'MI' }])
    end

    it 'should strip street address from city' do
      expect(importer.process_location_and_state('1800 W. Old Shakopee Road, Bloomington', 'Minnesota')).to eq(
        [{ city: 'Bloomington', state: 'MN' }]
      )
    end

    it 'should strip numeric prefixes from city' do
      expect(importer.process_location_and_state('25 - HINDS', 'Mississippi')).to eq(
        [{ city: 'HINDS', state: 'MS' }]
      )
    end

    it 'should strip trailing state' do
      expect(importer.process_location_and_state('Dutch Shisler Sobering Support Center, 1930 Boren Ave., Seattle, WA', 'Washington')).to eq(
        [{ city: 'Seattle', state: 'WA' }]
      )
    end

    it 'should strip trailing state and zip from city' do
      expect(importer.process_location_and_state('516 Third Ave, Room W-1033, Seattle, WA 98104', 'Washington')).to eq(
        [{ city: 'Seattle', state: 'WA' }]
      )
    end

    it 'should handle extra whitespace' do
      expect(importer.process_location_and_state('516 Third Ave, Room W-1033, Seattle,  WA  98104', 'Washington')).to eq(
        [{ city: 'Seattle', state: 'WA' }]
      )
    end

    it 'should strip trailing state and zip+4 from city' do
      expect(importer.process_location_and_state('516 Third Ave, Room W-1033, Seattle,WA 98104-1234', 'Washington')).to eq(
        [{ city: 'Seattle', state: 'WA' }]
      )
    end

    it 'should be nil if city contains "various" or "location"' do
      expect(importer.process_location_and_state('Various', 'Michigan')).to be_empty
      expect(importer.process_location_and_state('Multiple Vacancies and Locations', 'Michigan')).to be_empty
    end

    it 'should be nil if state is invalid' do
      expect(importer.process_location_and_state('Detroit', 'invalid')).to be_empty
    end
  end

  describe '#process_job_type' do
    it 'should find position_offering_type_code for internship' do
      expect(importer.process_job_type('Internship')).to eq(
        position_offering_type_code: 15_328, position_schedule_type_code: nil
      )
    end

    it 'should find position_offering_type_code and position_schedule_type_code for "permanent full time"' do
      expect(importer.process_job_type('Permanent Full Time')).to eq(
        position_offering_type_code: 15_317, position_schedule_type_code: 1
      )
    end

    it 'should find position_offering_type_code and position_schedule_type_code for "permanent Part-Time"' do
      expect(importer.process_job_type('Permanent Part Time (less than 40 hours per week)')).to eq(
        position_offering_type_code: 15_317, position_schedule_type_code: 2
      )
    end
  end

  describe '#process_salary(salary_str)' do
    it 'should round overly-precise decimal salaries to the penny' do
      expect(importer.process_salary('33.9993')).to eq(34.00)
      expect(importer.process_salary('43.0963')).to eq(43.10)
      expect(importer.process_salary('123456')).to eq(123_456)
    end
  end

  describe '#fetch_jobs_rss' do
    let(:http) { double('HTTP Object') }
    let(:request) { double('HTTP Request') }
    let(:response) { double('HTTP Response', body: 'some RSS') }

    before do
      allow(Net::HTTP).to receive(:new).with(NeogovData::HOST).and_return http
    end

    it 'should fetch the RSS for the agency' do
      expect(Net::HTTP::Get).to receive(:new).with("#{NeogovData::PATH}michigan", 'User-Agent' => NeogovData::USER_AGENT).and_return request
      expect(http).to receive(:request).with(request).and_return response
      expect(importer.fetch_jobs_rss).to eq('some RSS')
    end
  end
end
