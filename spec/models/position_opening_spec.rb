require 'spec_helper'

describe PositionOpening do
  before do
    PositionOpening.delete_search_index if PositionOpening.search_index.exists?
    PositionOpening.create_search_index
  end

  describe '.search_for(options)' do
    before do
      position_openings = []
      position_openings << {id: 1, type: 'position_opening', position_title: 'Deputy Special Assistant to the Chief Nurse Practitioner',
                            organization_id: 'AF09', organization_name: 'Air Force Personnel Center', position_schedule_type_code: 1,
                            start_date: Date.current, end_date: Date.tomorrow, minimum: 80000, maximum: 100000, rate_interval_code: 'PA',
                            locations: [{city: 'Andrews AFB', state: 'MD'},
                                        {city: 'Pentagon Arlington', state: 'VA'},
                                        {city: 'Air Force Academy', state: 'CO'}]}
      position_openings << {id: 2, type: 'position_opening', position_title: 'Physician Assistant', position_schedule_type_code: 2,
                            organization_id: 'VATA', organization_name: 'Veterans Affairs, Veterans Health Administration',
                            start_date: Date.current, end_date: Date.tomorrow, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                            locations: [{city: 'Fulton', state: 'MD'}]}
      position_openings << {id: 3, type: 'position_opening', position_title: 'Future Person',
                            organization_id: 'FUTU', organization_name: 'Future Administration', position_schedule_type_code: 2,
                            start_date: Date.current + 1, end_date: Date.current + 8, minimum: 17, maximum: 23, rate_interval_code: 'PH',
                            locations: [{city: 'San Francisco', state: 'CA'}]}
      position_openings << {id: 4, type: 'position_opening', position_title: 'Making No Money',
                            organization_id: 'FUTU', organization_name: 'Future Administration', position_schedule_type_code: 1,
                            start_date: Date.current, end_date: Date.current + 8, minimum: 0, maximum: 0, rate_interval_code: 'WC',
                            locations: [{city: 'San Francisco', state: 'CA'}]}


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
          remainder.split(',').each_with_index do |synonym, offset|
            id_number = starting_idx + (10 * (batch_number + 1))
            position_openings << {id: id_number + offset, type: 'position_opening', position_title: "Senior #{synonym}",
                                  organization_id: 'ABCD', organization_name: 'Sample Org', position_schedule_type_code: 1,
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
        res.first.should == {id: '1', position_title: 'Deputy Special Assistant to the Chief Nurse Practitioner',
                             organization_name: 'Air Force Personnel Center',
                             start_date: Date.current.to_s(:db), end_date: Date.tomorrow.to_s(:db),
                             minimum: 80000, maximum: 100000, rate_interval_code: 'PA',
                             locations: ['Andrews AFB, MD', 'Pentagon Arlington, VA', 'Air Force Academy, CO']}
      end
    end

    describe 'location searches' do
      it 'should find by state' do
        res = PositionOpening.search_for(query: 'jobs in maryland')
        res.first[:position_title].should == 'Physician Assistant'
        res.last[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
        res = PositionOpening.search_for(query: 'jobs md')
        res.first[:position_title].should == 'Physician Assistant'
        res.last[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
        res = PositionOpening.search_for(query: 'md jobs')
        res.first[:position_title].should == 'Physician Assistant'
        res.last[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
      end

      it 'should find by city' do
        res = PositionOpening.search_for(query: 'jobs in Arlington')
        res.first[:position_title].should == 'Deputy Special Assistant to the Chief Nurse Practitioner'
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
        res.first[:id].should == '2'
        res = PositionOpening.search_for(query: 'full-time opportunities in colorado')
        res.first[:id].should == '1'
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

    describe 'limiting result set size and starting point' do
      it 'should use the size param' do
        PositionOpening.search_for(query: 'jobs', size: 1).count.should == 1
        PositionOpening.search_for(query: 'jobs', size: 10).count.should == 3
      end

      it 'should use the from param' do
        PositionOpening.search_for(query: 'jobs', size: 1, from: 1).first[:id].should == '2'
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
        it 'should sort by descending IDs (i.e., newest first)' do
          res = PositionOpening.search_for(query: 'jobs')
          res.first[:id].should == '4'
          res.last[:id].should == '1'
        end
      end
    end

    describe 'searches on jobs with future starting dates' do
      it 'should not find the record' do
        PositionOpening.search_for(query: 'future person').size.should == 0
      end
    end
  end

  after(:all) do
    PositionOpening.delete_search_index
  end
end