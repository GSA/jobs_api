require 'spec_helper'

describe NeogovData do
  let(:importer) { NeogovData.new('michigan', 'doc/neogov_sample.rss', 'state', 'USMI') }

  describe '#import' do
    let!(:current_datetime) { DateTime.current.freeze }
    let!(:current) { current_datetime.to_date.freeze }
    let(:far_away) { Date.parse('2022-01-31') }
    let(:continuous_ttl) { "#{(current_datetime + 7).to_i - DateTime.parse('2012-03-12 10:16:56.14').to_datetime.to_i}s" }

    before { DateTime.stub(:current).and_return(current_datetime) }

    it 'should load the PositionOpenings from filename' do
      PositionOpening.should_receive(:get_external_ids_by_source).with('ng:michigan').and_return([])
      PositionOpening.should_receive(:import) do |position_openings|
        position_openings.length.should == 4

        position_openings[0].should ==
          {type: 'position_opening', source: 'ng:michigan',
           organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w(state),
           _timestamp: '2013-04-12T15:52:34+00:00', external_id: 634789,
           locations: [{city: 'Lansing', state: 'MI'}], _ttl: '277909586s',
           position_title: 'Professional Development and Training Intern-DHS',
           start_date: Date.parse('2013-04-12'), end_date: far_away, minimum: nil, maximum: nil,
           rate_interval_code: 'PH', position_offering_type_code: 15328, position_schedule_type_code: nil}

        position_openings[1].should ==
          {type: 'position_opening', source: 'ng:michigan',
           organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w(state),
           _timestamp: '2013-04-08T15:15:21+00:00', external_id: 631517,
           locations: [{city: 'Lansing', state: 'MI'}], _ttl: '278257419s',
           position_title: 'MEDC Corporate - Business Attraction Manager',
           start_date: Date.parse('2013-04-08'), end_date: far_away, minimum: 59334.0, maximum: 77066.0,
           rate_interval_code: 'PA', position_offering_type_code: 15317, position_schedule_type_code: 1}

        position_openings[2].should ==
          {type: 'position_opening', source: 'ng:michigan',
           organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w(state),
           _timestamp: '2012-03-12T10:16:56+00:00', external_id: 282662,
           locations: [{city: 'Freeland', state: 'MI'}],
           _ttl: continuous_ttl, position_title: 'Dentist-A',
           start_date: Date.parse('2011-09-23'), end_date: nil, minimum: 37.33, maximum: 51.66,
           rate_interval_code: 'PH', position_offering_type_code: 15317, position_schedule_type_code: 2}

        position_openings[3].should ==
          {type: 'position_opening', source: 'ng:michigan',
           organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w(state),
           _timestamp: '2010-08-10T16:07:30+00:00', external_id: 234175,
           locations: [{city: 'Munising', state: 'MI'}],
           _ttl: '362235090s', position_title: 'Registered Nurse Non-Career',
           start_date: Date.parse('2010-06-08'), end_date: far_away, minimum: 28.37, maximum: 38.87,
           rate_interval_code: 'PH', position_offering_type_code: nil, position_schedule_type_code: nil}
      end
      importer.import
    end

    it 'should expire position openings that are no longer in the feed' do
      less_entries_importer = NeogovData.new('michigan', 'spec/resources/neogov/less_items.rss', 'state', 'USMI')
      PositionOpening.should_receive(:get_external_ids_by_source).with('ng:michigan').and_return([282662])
      PositionOpening.should_receive(:import) do |position_openings|
        position_openings.length.should == 3

        position_openings[0].should ==
          {type: 'position_opening', source: 'ng:michigan',
           organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w(state),
           _timestamp: '2013-04-12T15:52:34+00:00', external_id: 634789,
           locations: [{city: 'Lansing', state: 'MI'}], _ttl: '277909586s',
           position_title: 'Professional Development and Training Intern-DHS',
           start_date: Date.parse('2013-04-12'), end_date: far_away, minimum: nil, maximum: nil,
           rate_interval_code: 'PH', position_offering_type_code: 15328, position_schedule_type_code: nil}

        position_openings[1].should ==
          {type: 'position_opening', source: 'ng:michigan',
           organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w(state),
           _timestamp: '2013-04-08T15:15:21+00:00', external_id: 631517,
           locations: [{city: 'Lansing', state: 'MI'}], _ttl: '278257419s',
           position_title: 'MEDC Corporate - Business Attraction Manager',
           start_date: Date.parse('2013-04-08'), end_date: far_away, minimum: 59334.0, maximum: 77066.0,
           rate_interval_code: 'PA', position_offering_type_code: 15317, position_schedule_type_code: 1}

        position_openings[2].should ==
          {type: 'position_opening', source: 'ng:michigan', external_id: 282662, _ttl: '1s'}
      end
      less_entries_importer.import
    end

    it 'should set _ttl to 1s for invalid/expired position openings' do
      expired_importer = NeogovData.new('michigan', 'spec/resources/neogov/expired.rss', 'state', 'USMI')
      PositionOpening.should_receive(:get_external_ids_by_source).with('ng:michigan').and_return([])
      PositionOpening.should_receive(:import) do |position_openings|
        position_openings.length.should == 1

        position_openings[0].should ==
          {type: 'position_opening', source: 'ng:michigan',
           organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w(state),
           external_id: 282662, locations: [{city: 'Freeland', state: 'MI'}], _ttl: '1s'}
      end
      expired_importer.import
    end

    it 'should set location to an empty array when the city or state is invalid' do
      bad_location_importer = NeogovData.new('michigan', 'spec/resources/neogov/bad_locations.rss', 'state', 'USMI')
      PositionOpening.should_receive(:get_external_ids_by_source).with('ng:michigan').and_return([])
      PositionOpening.should_receive(:import) do |position_openings|
        position_openings.length.should == 1

        position_openings[0].should ==
          {type: 'position_opening', source: 'ng:michigan',
           organization_id: 'USMI', organization_name: 'State of Michigan, MI', tags: %w(state),
           external_id: 386302, locations: [], _ttl: '1s'}
      end
      bad_location_importer.import
    end

    context 'when organization_name is defined' do
      let(:no_org_name_importer) { NeogovData.new('michigan', 'doc/neogov_sample.rss', 'state', 'USMI', 'State of Michigan') }

      it 'should use the predefined organization name' do
        PositionOpening.should_receive(:get_external_ids_by_source).with('ng:michigan').and_return([])
        PositionOpening.should_receive(:import) do |position_openings|
          position_openings.length.should == 4
          position_openings.map { |po| po[:organization_name] }.uniq.should == ['State of Michigan']
        end
        no_org_name_importer.import
      end
    end
  end

  describe '#process_location_and_state' do
    it 'should convert state name to state abbreviation' do
      importer.process_location_and_state('Lansing', 'Michigan').should == [{city: 'Lansing', state: 'MI'}]
    end

    it 'should strip street address from city' do
      importer.process_location_and_state('1800 W. Old Shakopee Road, Bloomington', 'Minnesota').should ==
        [{city: 'Bloomington', state: 'MN'}]
    end

    it 'should be nil if city contains "various" or "location"' do
      importer.process_location_and_state('Various', 'Michigan').should be_empty
      importer.process_location_and_state('Multiple Vacancies and Locations', 'Michigan').should be_empty
    end

    it 'should be nil if state is invalid' do
      importer.process_location_and_state('Detroit', 'invalid').should be_empty
    end
  end

  describe '#process_job_type' do
    it 'should find position_offering_type_code for internship' do
      importer.process_job_type('Internship').should ==
        {position_offering_type_code: 15328, position_schedule_type_code: nil}
    end

    it 'should find position_offering_type_code and position_schedule_type_code for "permanent full time"' do
      importer.process_job_type('Permanent Full Time').should ==
        {position_offering_type_code: 15317, position_schedule_type_code: 1}
    end

    it 'should find position_offering_type_code and position_schedule_type_code for "permanent Part-Time"' do
      importer.process_job_type('Permanent Part Time (less than 40 hours per week)').should ==
        {position_offering_type_code: 15317, position_schedule_type_code: 2}
    end
  end
end
