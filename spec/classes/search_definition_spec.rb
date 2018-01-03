require 'rails_helper'

describe SearchDefinition do
  let(:expected_definition) { { bool: { must: [], should: [] } } }

  describe '.new' do
    context 'when there is no definition being set' do
      it 'returns the default definition' do
        expect(SearchDefinition.new.definition).to eq(
          {
            query: {
              bool: {
                must: [],
                should: []
              }
            }
          }
        )
      end
    end

    context 'when there is definition being set' do
      it 'returns the set definition' do
        expect(SearchDefinition.new(expected_definition).definition).to eq(expected_definition)
      end
    end
  end

  describe '.must' do
    context 'when there is query in definition' do
      it 'adds query to definition' do
        search = SearchDefinition.new do |s|
          s.must({ terms: { tags: [1, 2, 3] }})
        end

        expect(search.definition[:query][:bool][:must]).to eq([{ terms: { tags: [1, 2, 3] } }])
      end
    end

    context 'when there is no query in definition' do
      it 'adds query to bool' do
        search = SearchDefinition.new(expected_definition) do |s|
          s.must({ match: { tag: 1 }})
        end

        expect(search.definition[:bool][:must]).to eq([{ match: { tag: 1 } }])
      end
    end
  end

  describe '.should' do
    context 'when there is query in definition' do
      it 'adds query to definition' do
        search = SearchDefinition.new do |s|
          s.should({ term: { name: 'apple' }})
        end

        expect(search.definition[:query][:bool][:should]).to eq([{ term: { name: 'apple' } }])
      end
    end

    context 'when there is no query in definition' do
      it 'adds query to bool' do
        search = SearchDefinition.new(expected_definition) do |s|
          s.should({ match: { pretty: true }})
        end

        expect(search.definition[:bool][:should]).to eq([{ match: { pretty: true } }])
      end
    end
  end

  describe '.sort' do
    it 'adds sorting query' do
      search = SearchDefinition.new do |s|
        s.sort({ id: 'desc' })
      end

      expect(search.definition[:sort]).to eq({ id: 'desc' })
    end
  end

  describe '.to_s' do
    it 'prints out definition' do
      expect(SearchDefinition.new(expected_definition).to_s).to eq(expected_definition)
    end
  end
end
