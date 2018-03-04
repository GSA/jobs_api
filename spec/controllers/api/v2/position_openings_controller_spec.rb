# frozen_string_literal: true

require 'rails_helper'

describe Api::V2::PositionOpeningsController do
  describe '#search' do
    let(:search_params) do
      { 'query' => 'tsa jobs', 'organization_id' => 'ABCD', 'tags' => 'state city', 'from' => '2', 'size' => '3',
        'hl' => '1', 'lat_lon' => '37.41919999999,-122.0574' }
    end

    let(:search_results) { double('search results') }

    before do
      expect(PositionOpening).to receive(:search_for).with(search_params).and_return(search_results)
      get 'search', params: {
        query: 'tsa jobs', organization_id: 'ABCD', tags: 'state city', from: '2', size: '3', hl: '1',
        lat_lon: '37.41919999999,-122.0574', format: :json
      }
    end

    it { is_expected.to respond_with(:success) }

    it 'should respond with content type json' do
      expect(response.content_type).to match(/json/)
    end

    it 'should assign search results to position openings' do
      expect(assigns[:position_openings]).to eq(search_results)
    end

    it { is_expected.to render_template(:search) }
  end
end
