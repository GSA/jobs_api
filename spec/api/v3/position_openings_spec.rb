require 'spec_helper'

describe 'Position Openings API V3' do
  before do
    PositionOpening.delete_search_index if PositionOpening.search_index.exists?
    PositionOpening.create_search_index

    UsajobsData.new('doc/sample.xml').import
    neogov = NeogovData.new('michigan', 'state', 'USMI')
    allow(neogov).to receive(:fetch_jobs_rss).and_return File.open('doc/neogov_sample.rss')
    neogov.import
  end

  describe 'GET /search.json' do
    context 'when format is JSON' do
      context 'when searching for existing jobs in a particular organization' do
        before { get '/search.json', { query: 'nursing jobs', hl: 1 } }

        it 'should respond with status code 200' do
          expect(response.status).to eq(200)
        end

        it 'should respond with content type json' do
          expect(response.content_type).to eq(:json)
        end

        it 'should return with jobs data' do
          results_array = JSON.parse(response.body)
          expect(results_array.size).to eq(2)
          expect(results_array.first).to eq({'id'=>'usajobs:327358300', 'position_title'=>'Student <em>Nurse</em> Technicians',
                                         'organization_name'=>'Veterans Affairs, Veterans Health Administration',
                                         'rate_interval_code'=>'PH', 'minimum'=>17, 'maximum'=>23,
                                         'start_date'=>'2012-09-19', 'end_date'=>'2022-01-31',
                                         'locations'=>['Odessa, TX', 'Pentagon, Arlington, VA', 'San Angelo, TX', 'Abilene, TX'],
                                         'url' => 'https://www.usajobs.gov/GetJob/ViewDetails/327358300'})

          expect(results_array.last).to eq({'id'=>'ng:michigan:234175', 'position_title'=>'Registered <em>Nurse</em> Non-Career',
                                        'organization_name'=>'State of Michigan, MI',
                                        'rate_interval_code'=>'PH', 'minimum'=>28.37, 'maximum'=>38.87,
                                        'start_date'=>'2010-06-08', 'end_date'=>'2022-01-31',
                                        'locations'=>['Munising, MI'],
                                        'url' => 'http://agency.governmentjobs.com/michigan/default.cfm?action=viewjob&jobid=234175'})
        end
      end

      context 'when searching for non-existing jobs' do
        before { get '/search.json', { query: 'astronaut jobs', hl: 1 } }

        it 'should respond with status code 200' do
          expect(response.status).to eq(200)
        end

        it 'should respond with content type json' do
          expect(response.content_type).to eq(:json)
        end

        it 'should return with empty array' do
          results_array = JSON.parse(response.body)
          expect(results_array).to eq([])
        end
      end
    end
  end

  after(:all) { PositionOpening.delete_search_index }
end
