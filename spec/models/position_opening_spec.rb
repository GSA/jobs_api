require 'spec_helper'

describe PositionOpening do
  before do
    PositionOpening.delete_search_index if PositionOpening.search_index.exists?
    PositionOpening.create_search_index
  end

  describe '.search_for(options)' do
    before do
      position_openings = []
      position_openings << {source: 'usajobs', external_id: 1, type: 'position_opening', position_title: 'Deputy Special Assistant to the Chief Nurse Practitioner',
                            organization_id: 'AF09', organization_name: 'Air Force Personnel Center',
                            position_schedule_type_code: 1, position_offering_type_code: 15317, tags: %w(federal),
                            start_date: Date.current, end_date: Date.tomorrow, minimum: 80000, maximum: 100000, rate_interval_code: 'PA',
                            locations: [{city: 'Andrews AFB', state: 'MD'},
                                        {city: 'Pentagon Arlington', state: 'VA'},
                                        {city: 'Air Force Academy', state: 'CO'}]}
      position_openings << {source: 'usajobs', external_id: 2, type: 'position_opening', position_title: 'Physician Assistant',
                            position_schedule_type_code: 2, position_offering_type_code: 15318, tags: %w(federal),
                            organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
                            start_date: Date.current, end_date: Date.tomorrow, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                            locations: [{city: 'Fulton', state: 'MD'}]}
      position_openings << {source: 'usajobs', external_id: 3, type: 'position_opening', position_title: 'Future Person',
                            organization_id: 'FUTU', organization_name: 'Future Administration',
                            position_schedule_type_code: 2, position_offering_type_code: 15327, tags: %w(federal),
                            start_date: Date.current + 1, end_date: Date.current + 8, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                            locations: [{city: 'San Francisco', state: 'CA'}]}
      position_openings << {source: 'usajobs', external_id: 4, type: 'position_opening', position_title: 'Making No Money',
                            organization_id: 'FUTU', organization_name: 'Future Administration',
                            position_schedule_type_code: 1, position_offering_type_code: 15328, tags: %w(federal),
                            start_date: Date.current, end_date: Date.current + 8, minimum: 0, maximum: 0, rate_interval_code: 'WC',
                            locations: [{city: 'San Francisco', state: 'CA'}]}
      position_openings << {type: 'position_opening', source: 'ng:michigan', _timestamp: Date.current.weeks_ago(1).iso8601, external_id: 629140,
                            locations: [{city: 'Lansing', state: 'MI'}], tags: %w(state),
                            rate_interval_code: 'PH', position_schedule_type_code: 1, position_offering_type_code: 15317,
                            position_title: 'Supervisor (DOH #28425)',
                            start_date: Date.current, end_date: Date.current.tomorrow, minimum: 20.7, maximum: 36.8}
      position_openings << {type: 'position_opening', source: 'ng:michigan', _timestamp: Date.current.yesterday.iso8601, external_id: 616313,
                            locations: [{city: 'Detroit', state: 'MI'}], tags: %w(state),
                            rate_interval_code: 'PH', position_schedule_type_code: 1, position_offering_type_code: 15322,
                            position_title: 'Indoor Lifeguard',
                            start_date: Date.current, end_date: Date.current + 8, minimum: 15.68, maximum: 27.11}
      position_openings << {type: 'position_opening', source: 'ng:bloomingtonmn', _timestamp: Date.current.iso8601, external_id: 632865,
                            locations: [{city: 'Detroit', state: 'MI'}], tags: %w(city),
                            rate_interval_code: 'PA', position_schedule_type_code: 1, position_offering_type_code: 15317,
                            position_title: 'Computer Specialist',
                            start_date: Date.current, end_date: Date.current + 8, minimum: 55000, maximum: 60000}

      PositionOpening.import position_openings
    end

    describe 'stemming of position titles' do
      it 'should find and optionally highlight position title matches' do
        res = PositionOpening.search_for(query: 'nursing jobs', hl: '1')
        res.size.should == 1
      end
    end

    context 'when query terms contain a synonym match with terms in job title' do
      before do
        position_openings, starting_idx = [], 10
        @first_synonyms = []
        open(Rails.root.join('config', 'synonyms.txt')).each_with_index do |batch_str, batch_number|
          first_synonym, remainder = batch_str.gsub(/ ?, ?/, ',').split(',', 2)
          @first_synonyms << first_synonym
          id_number = starting_idx + (10 * (batch_number + 1))
          remainder.split(',').each_with_index do |synonym, offset|
            position_openings << {source: 'usajobs', external_id: id_number + offset, type: 'position_opening', position_title: "Senior #{synonym}",
                                  organization_id: 'ABCD', organization_name: 'Sample Org',
                                  position_schedule_type_code: 1, position_offering_type_code: 15317,
                                  start_date: Date.current, end_date: Date.current + 8, minimum: 100000, maximum: 200000, rate_interval_code: 'PA',
                                  locations: [{city: 'San Francisco', state: 'CA'}]}

          end
        end
        PositionOpening.import position_openings
      end

      it 'should find the matches' do
        @first_synonyms.each do |synonym|
          PositionOpening.search_for(query: synonym, organization_id: 'ABCD').size.should > 0
        end
      end
    end

    describe 'highlighting of position titles' do
      it 'should optionally highlight position title matches' do
        res = PositionOpening.search_for(query: 'nursing', hl: '1')
        res.first[:position_title].should == 'Deputy Special Assistant to the Chief <em>Nurse</em> Practitioner'
        res = PositionOpening.search_for(query: 'nurse')
        res.first[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
      end
    end

    describe 'result fields' do
      it 'should contain the minimal necessary fields' do
        res = PositionOpening.search_for(query: 'nursing jobs')
        res.first.should == {id: 'usajobs:1', source: 'usajobs', external_id: 1,
                             position_title: 'Deputy Special Assistant to the Chief Nurse Practitioner',
                             organization_name: 'Air Force Personnel Center',
                             start_date: Date.current.to_s(:db), end_date: Date.tomorrow.to_s(:db),
                             minimum: 80000, maximum: 100000, rate_interval_code: 'PA',
                             locations: ['Andrews AFB, MD', 'Pentagon Arlington, VA', 'Air Force Academy, CO'],
                             url: 'https://www.usajobs.gov/GetJob/ViewDetails/1'}
      end
    end

    describe 'location searches' do
      it 'should find by state' do
        res = PositionOpening.search_for(query: 'jobs in maryland', sort_by: :id)
        res.first[:position_title].should == 'Physician Assistant'
        res.last[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
        res = PositionOpening.search_for(query: 'jobs md', sort_by: :id)
        res.first[:position_title].should == 'Physician Assistant'
        res.last[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
        res = PositionOpening.search_for(query: 'md jobs', sort_by: :id)
        res.first[:position_title].should == 'Physician Assistant'
        res.last[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
      end

      it 'should find by city' do
        res = PositionOpening.search_for(query: 'jobs in Arlington')
        res.first[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'

        PositionOpening.search_for(query: 'fulton jobs').first[:locations].first.should match(/Fulton/)
        PositionOpening.search_for(query: 'san arlington jobs').should be_empty
      end

      it 'should find by city and state' do
        res = PositionOpening.search_for(query: 'jobs in Arlington, va')
        res.first[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
      end

      it 'should not find by one city and another state' do
        res = PositionOpening.search_for(query: 'jobs in Arlington, md')
        res.should be_empty
      end
    end

    describe 'searches for volunteer jobs' do
      it 'should restrict search to jobs with rate interval code of WC' do
        res = PositionOpening.search_for(query: 'volunteer jobs')
        res.first[:position_title].should == 'Making No Money'
      end
    end

    describe 'searches for part-time/full-time jobs' do
      it 'should restrict search to jobs with appropriate remuneration codes' do
        res = PositionOpening.search_for(query: 'part-time jobs')
        res.first[:id].should == 'usajobs:2'
        res = PositionOpening.search_for(query: 'full-time opportunities in colorado')
        res.first[:id].should == 'usajobs:1'
      end
    end

    describe 'searches for intern jobs' do
      it 'should restrict search to jobs with appropriate position offering type code' do
        res = PositionOpening.search_for(query: 'seasonal jobs')
        res.first[:id].should == 'ng:michigan:616313'
        res = PositionOpening.search_for(query: 'internship jobs')
        res.first[:id].should == 'usajobs:4'
      end
    end

    describe 'implicit organization searches' do
      before do
        Agencies.stub!(:find_organization_id).and_return 'VATA'
      end

      it "should find for queries like 'at the nsa'" do
        res = PositionOpening.search_for(query: 'opportunities at the nsa')
        res.first[:position_title].should == 'Physician Assistant'
      end

      it "should find for queries like 'nsa jobs'" do
        res = PositionOpening.search_for(query: 'nsa employment')
        res.first[:position_title].should == 'Physician Assistant'
      end
    end

    describe 'explicit organization searches' do
      it "should find for full org id's" do
        res = PositionOpening.search_for(organization_id: 'VATA')
        res.size.should == 1
        res.first[:position_title].should == 'Physician Assistant'
      end

      it 'should find for org id prefixes' do
        res = PositionOpening.search_for(query: 'jobs', organization_id: 'VA')
        res.first[:position_title].should == 'Physician Assistant'
      end
    end

    describe 'tags search' do
      it 'should find federal job openings' do
        res = PositionOpening.search_for(tags: 'federal')
        res.size.should == 3
        res.map { |p| p[:source] }.uniq.should == %w(usajobs)
      end

      it 'should find state and city job openings' do
        res = PositionOpening.search_for(tags: 'state city')
        res.size.should == 3
        res.map { |p| p[:source] }.uniq.should == %w(ng:bloomingtonmn ng:michigan)
      end
    end

    describe 'limiting result set size and starting point' do
      it 'should use the size param' do
        PositionOpening.search_for(query: 'jobs', size: 1).count.should == 1
        PositionOpening.search_for(query: 'jobs', size: 10).count.should == 6
      end

      it 'should use the from param' do
        PositionOpening.search_for(query: 'jobs', size: 1, from: 1, sort_by: :id).first[:id].should == 'usajobs:2'
      end
    end

    describe 'sorting' do
      context 'when keywords present' do
        it 'should sort by relevance' do
          res = PositionOpening.search_for(query: 'physician nursing Practitioner')
          res.first[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
          res.last[:position_title].should == 'Physician Assistant'
        end
      end

      context 'when keywords not present' do
        context 'when sort_by option is not set' do
          context 'when location is set' do
            before do
              position_openings = []
              position_openings << {source: 'usajobs', external_id: 4000, type: 'position_opening', position_title: 'Physician Assistant New',
                                    position_schedule_type_code: 2, position_offering_type_code: 15318, tags: %w(federal),
                                    organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
                                    start_date: Date.current, end_date: Date.tomorrow, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                                    locations: [
                                      {city: 'Tempe', state: 'AZ', geo: {lat: 33.429444, lon: -111.943}}
                                    ]}
              position_openings << {source: 'usajobs', external_id: 4001, type: 'position_opening', position_title: 'Physician Assistant New',
                                    position_schedule_type_code: 2, position_offering_type_code: 15318, tags: %w(federal),
                                    organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
                                    start_date: Date.current, end_date: Date.tomorrow, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                                    locations: [
                                      {city: 'Las Vegas', state: 'NV', geo: {lat: 36.175, lon: -115.136389}},
                                      {city: 'Baltimore', state: 'MD', geo: {lat: 39.283333, lon: -76.616667}}
                                    ]}
              position_openings << {source: 'usajobs', external_id: 4002, type: 'position_opening', position_title: 'Physician Assistant New',
                                    position_schedule_type_code: 2, position_offering_type_code: 15318, tags: %w(federal),
                                    organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
                                    start_date: Date.current, end_date: Date.tomorrow, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                                    locations: [
                                      {city: 'Flagstaff', state: 'AZ', geo: {lat: 35.199167, lon: -111.631111}}
                                    ]}
              PositionOpening.import position_openings
            end

            it 'should sort by closest minimum distance from user to job locations' do
              res = PositionOpening.search_for(query: 'jobs', size: 1, lat_lon: '35.115556,-114.588611') # Bullhead City, AZ
              res.first[:id].should == 'usajobs:4001'

              res = PositionOpening.search_for(query: 'jobs in arizona', size: 1, lat_lon: '35.199167,-115.136389') # close to Vegas
              res.first[:id].should == 'usajobs:4002'
            end
          end

          context 'when location is not set' do
            before do
              position_openings = [{source: 'usajobs', external_id: 1000, type: 'position_opening', position_title: 'Physician Assistant New',
                                    position_schedule_type_code: 2, position_offering_type_code: 15318, tags: %w(federal),
                                    organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
                                    start_date: Date.current, end_date: Date.tomorrow, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                                    locations: [{city: 'Fulton', state: 'MD'}]}]
              PositionOpening.import position_openings
              sleep(0.25)
              position_openings = [{source: 'usajobs', external_id: 1001, type: 'position_opening', position_title: 'Physician Assistant Newer',
                                    position_schedule_type_code: 2, position_offering_type_code: 15318, tags: %w(federal),
                                    organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
                                    start_date: Date.current, end_date: Date.tomorrow, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                                    locations: [{city: 'Fulton', state: 'MD'}]}]
              PositionOpening.import position_openings
              sleep(0.25)
              position_openings = [{source: 'usajobs', external_id: 1002, type: 'position_opening', position_title: 'Physician Assistant Newest',
                                    position_schedule_type_code: 2, position_offering_type_code: 15318, tags: %w(federal),
                                    organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
                                    start_date: Date.current, end_date: Date.tomorrow, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                                    locations: [{city: 'Fulton', state: 'MD'}]}]
              PositionOpening.import position_openings
            end

            it 'should sort by descending timestamp (i.e., newest first)' do
              res = PositionOpening.search_for(query: 'jobs', size: 3)
              res.first[:id].should == 'usajobs:1002'
              res.last[:id].should == 'usajobs:1000'
            end
          end
        end

        context 'when sort_by option is set to :id' do
          it 'should sort by descending IDs' do
            res = PositionOpening.search_for(query: 'jobs', sort_by: :id)
            res.first[:id].should == 'usajobs:4'
            res.last[:id].should == 'ng:bloomingtonmn:632865'
          end
        end
      end
    end

    describe 'searches on jobs with future starting dates' do
      it 'should not find the record' do
        PositionOpening.search_for(query: 'future person').size.should == 0
      end
    end

    describe "queries is of form 'nursing jobs at the va' or 'phlebotomy jobs in Ohio' or 'atlanta jobs at the ssa'" do
      it 'should require at least the position title or location to match' do
        PositionOpening.search_for(query: 'foobar jobs in virginia').should be_empty
        PositionOpening.search_for(query: 'pentagon jobs', organization_id: 'VA').should be_empty
        PositionOpening.search_for(query: 'foobar jobs', organization_id: 'VA').should be_empty
      end
    end

    describe 'when source is specified' do
      it 'should find results only from the matching source' do
        res = PositionOpening.search_for(query: 'jobs', source: 'usajobs')
        res.size.should == 3
        res.map { |j| j[:source] }.uniq.should == %w(usajobs)

        res = PositionOpening.search_for(query: 'jobs', source: 'ng:michigan')
        res.size.should == 2
        res.map { |j| j[:source] }.uniq.should == %w(ng:michigan)

        PositionOpening.search_for(query: 'jobs', source: 'ng').should be_empty
      end
    end
  end

  describe '.get_external_ids_by_source' do
    before do
      position_openings = []
      position_openings << {source: 'usajobs', external_id: 1, type: 'position_opening', position_title: 'Deputy Special Assistant to the Chief Nurse Practitioner',
                            organization_id: 'AF09', organization_name: 'Air Force Personnel Center', position_schedule_type_code: 1,
                            start_date: Date.current, end_date: Date.tomorrow, minimum: 80000, maximum: 100000, rate_interval_code: 'PA',
                            locations: [{city: 'Andrews AFB', state: 'MD'},
                                        {city: 'Pentagon Arlington', state: 'VA'},
                                        {city: 'Air Force Academy', state: 'CO'}]}
      position_openings << {source: 'usajobs', external_id: 2, type: 'position_opening', position_title: 'Physician Assistant', position_schedule_type_code: 2,
                            organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
                            start_date: Date.current, end_date: Date.tomorrow, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                            locations: [{city: 'Fulton', state: 'MD'}]}
      position_openings << {source: 'usajobs', external_id: 3, type: 'position_opening', position_title: 'Future Person',
                            organization_id: 'FUTU', organization_name: 'Future Administration', position_schedule_type_code: 2,
                            start_date: Date.current + 1, end_date: Date.current + 8, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                            locations: [{city: 'San Francisco', state: 'CA'}]}
      position_openings << {source: 'usajobs', external_id: 4, type: 'position_opening', position_title: 'Making No Money',
                            organization_id: 'FUTU', organization_name: 'Future Administration', position_schedule_type_code: 1,
                            start_date: Date.current, end_date: Date.current + 8, minimum: 0, maximum: 0, rate_interval_code: 'WC',
                            locations: [{city: 'San Francisco', state: 'CA'}]}
      position_openings << {source: 'ng:michigan', external_id: 629140, type: 'position_opening', position_title: 'Supervisor (DOH #28425)',
                            position_schedule_type_code: 1,
                            start_date: Date.current, end_date: Date.tomorrow, minimum: 20.7, maximum: 36.8, rate_interval_code: 'PH',
                            locations: [{city: 'Lansing', state: 'MI'}]}
      PositionOpening.import position_openings
    end

    it 'should return external_ids' do
      PositionOpening.get_external_ids_by_source('usajobs').should == [1, 2, 3, 4]
      PositionOpening.get_external_ids_by_source('ng:michigan').should == [629140]
      PositionOpening.get_external_ids_by_source('ng').should be_empty
    end
  end

  describe '.import(position_openings)' do
    let(:position_opening) do
      {source: 'usajobs', external_id: 1, type: 'position_opening', position_title: 'Some job',
       organization_id: 'AF09', organization_name: 'Air Force Personnel Center',
       position_schedule_type_code: 1, position_offering_type_code: 15317, tags: %w(federal),
       start_date: Date.current, end_date: Date.tomorrow, minimum: 80000, maximum: 100000, rate_interval_code: 'PA',
       locations: [{city: 'Andrews AFB', state: 'MD'},
                   {city: 'Washington Metro Area', state: 'DC'},
                   {city: 'Maui Island, Hawaii', state: 'HI'}]}
    end

    it 'should geocode each normalized job location' do
      Geoname.should_receive(:geocode).with(location: 'Andrews AFB', state: 'MD').and_return({lat: 12.34, lon: -23.45})
      Geoname.should_receive(:geocode).with(location: 'Washington', state: 'DC').and_return({lat: 23.45, lon: -12.34})
      Geoname.should_receive(:geocode).with(location: 'Maui Island', state: 'HI').and_return({lat: 45.67, lon: -13.31})
      PositionOpening.import([position_opening])
      position_openings = Tire.search 'test:jobs' do
        query { all }
      end
      position_openings.results.first[:locations][0][:geo].to_hash.should == {lat: 12.34, lon: -23.45}
      position_openings.results.first[:locations][1][:geo].to_hash.should == {lat: 23.45, lon: -12.34}
      position_openings.results.first[:locations][2][:geo].to_hash.should == {lat: 45.67, lon: -13.31}
    end

    context 'when no location information is present for job' do
      let(:position_opening_no_locations) do
        {source: 'usajobs', external_id: 1999, type: 'position_opening', position_title: 'Some job no locations',
         organization_id: 'AF09', organization_name: 'Air Force Personnel Center',
         position_schedule_type_code: 1, position_offering_type_code: 15317, tags: %w(federal),
         start_date: Date.current, end_date: Date.tomorrow, minimum: 80000, maximum: 100000, rate_interval_code: 'PA'}
      end

      it 'should leave locations empty' do
        PositionOpening.import([position_opening_no_locations])
        position_openings = Tire.search 'test:jobs' do
          query { all }
        end
        position_openings.results.first[:locations].should be_nil
      end

    end
  end

  after(:all) do
    PositionOpening.delete_search_index
  end
end