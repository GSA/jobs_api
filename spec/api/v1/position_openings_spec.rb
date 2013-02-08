require 'spec_helper'

describe 'Position Openings API V1' do
  before(:all) do
    PositionOpening.delete_search_index if PositionOpening.search_index.exists?
    PositionOpening.create_search_index
    importer = UsajobsData.new('doc/sample.xml')
    importer.import
  end

  describe 'GET /search.json' do
    context 'when format is JSON' do
      context 'when searching for existing jobs in a particular organization' do
        before { get '/search.json', organization: 'VATA', query: 'nursing jobs', hl: 1 }

        it 'should respond with status code 200' do
          response.status.should == 200
        end

        it 'should respond with content type json' do
          response.content_type.should == :json
        end

        it 'should return with jobs data' do
          results_array = JSON.parse(response.body)
          results_array.size.should == 1
          results_array.first.should == {'id'=>'327358300', 'position_title'=>'Student <em>Nurse</em> Technicians',
                                         'organization_name'=>'Veterans Affairs, Veterans Health Administration',
                                         'rate_interval_code'=>'PH', 'minimum'=>17, 'maximum'=>23,
                                         'start_date'=>'2012-09-19', 'end_date'=>'2022-01-31',
                                         'locations'=>['Odessa, TX', 'Pentagon, Arlington, VA', 'San Angelo, TX', 'Abilene, TX']}
        end
      end

      context 'when searching for non-existing jobs' do
        before { get '/search.json', query: 'astronaut jobs', hl: 1 }

        it 'should respond with status code 200' do
          response.status.should == 200
        end

        it 'should respond with content type json' do
          response.content_type.should == :json
        end

        it 'should return with empty array' do
          results_array = JSON.parse(response.body)
          results_array.should == []
        end
      end
    end
  end

  after(:all) do
    PositionOpening.delete_search_index
  end

end