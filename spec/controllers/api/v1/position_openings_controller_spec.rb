require 'spec_helper'

describe Api::V1::PositionOpeningsController do
  describe '#search' do
    let(:search_params) do
      {'query' => 'tsa jobs', 'organization_id' => 'ABCD', 'from' => '2', 'size' => '3', 'hl' => '1'}
    end

    let(:search_results) do
      [{id: '1', position_title: 'Nurse Practitioner', organization_name: 'Air Force Personnel Center',
        locations: ['Andrews AFB, MD', 'Pentagon Arlington, VA', 'Air Force Academy, CO']},
       {id: '2', position_title: 'Park Ranger', organization_name: 'National Park Service', locations: ['Ukiah, WA']}
      ]
    end

    before do
      PositionOpening.should_receive(:search_for).with(search_params).and_return(search_results)
      get 'search', query: 'tsa jobs', organization_id: 'ABCD', from: '2', size: '3', hl: '1', format: :json
    end

    it { should respond_with(:success) }
    it { should respond_with_content_type(/json/) }

    it 'should respond with search results' do
      response_hash = JSON.parse(response.body)
      response_hash.should == search_results.as_json
    end
  end
end