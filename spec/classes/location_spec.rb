require 'rails_helper'

describe Location do
  describe '.new(location)' do
    context 'when only state abbreviation is passed in' do
      let(:location) { Location.new('ny') }
      it 'should set the state and leave city blank' do
        expect(location.state).to eq('NY')
        expect(location.city).to be_blank
      end
    end

    context 'when only state name is passed in' do
      let(:location) { Location.new('Federated States of Micronesia') }
      it 'should set the state and leave city blank' do
        expect(location.state).to eq('FM')
        expect(location.city).to be_blank
      end
    end

    context 'when only city name is passed in' do
      let(:location) { Location.new('small town') }
      it 'should set the city and leave state blank' do
        expect(location.city).to eq('small town')
        expect(location.state).to be_blank
      end
    end

    context 'when city and state name are passed in' do
      let(:location) { Location.new('albuquerque new mexico') }
      it 'should set the city and state' do
        expect(location.state).to eq('NM')
        expect(location.city).to eq('albuquerque')
      end
    end

    context 'when city and state abbreviation are passed in' do
      let(:location) { Location.new('albuquerque nm') }
      it 'should set the city and state' do
        expect(location.state).to eq('NM')
        expect(location.city).to eq('albuquerque')
      end
    end

  end
end
