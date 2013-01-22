require 'spec_helper'

describe Location do
  describe '.new(location)' do
    context 'when only state abbreviation is passed in' do
      let(:location) { Location.new('ny') }
      it 'should set the state and leave city blank' do
        location.state.should == 'NY'
        location.city.should be_blank
      end
    end

    context 'when only state name is passed in' do
      let(:location) { Location.new('Federated States of Micronesia') }
      it 'should set the state and leave city blank' do
        location.state.should == 'FM'
        location.city.should be_blank
      end
    end

    context 'when only city name is passed in' do
      let(:location) { Location.new('small town') }
      it 'should set the city and leave state blank' do
        location.city.should == 'small town'
        location.state.should be_blank
      end
    end

    context 'when city and state name are passed in' do
      let(:location) { Location.new('albuquerque new mexico') }
      it 'should set the city and state' do
        location.state.should == 'NM'
        location.city.should == 'albuquerque'
      end
    end

    context 'when city and state abbreviation are passed in' do
      let(:location) { Location.new('albuquerque nm') }
      it 'should set the city and state' do
        location.state.should == 'NM'
        location.city.should == 'albuquerque'
      end
    end

  end
end