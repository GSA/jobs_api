require 'spec_helper'

describe Api::V2::PositionOpeningsController do
  describe '#search' do
    let(:search_params) do
      {'query' => 'tsa jobs', 'organization_id' => 'ABCD', 'tags' => 'state city', 'from' => '2', 'size' => '3', 'hl' => '1'}
    end

    let(:search_results) { mock('search results') }

    before do
      PositionOpening.should_receive(:search_for).with(search_params).and_return(search_results)
      get 'search', query: 'tsa jobs', organization_id: 'ABCD', tags: 'state city', from: '2', size: '3', hl: '1', format: :json
    end

    it { should respond_with(:success) }
    it { should respond_with_content_type(/json/) }
    it { should assign_to(:position_openings).with(search_results) }
    it { should render_template(:search) }
  end
end