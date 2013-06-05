require 'spec_helper'

describe Geoname do
  before do
    Geoname.delete_search_index if Geoname.search_index.exists?
    Geoname.create_search_index
  end

  describe '.geocode(options)' do

    describe 'basic location/state lookup' do
      before do
        Geoname.import [{type: 'geoname', location: "Someplace", state: 'XY', geo: {lat: 12.34, lon: -123.45}}]
      end

      it 'should return the lat/lon hash of the place' do
        Geoname.geocode(location: "Someplace", state: 'XY').should == {lat: 12.34, lon: -123.45}
      end
    end


    context 'when query terms contain a synonym match with terms in location field' do
      before do
        geonames, @first_synonyms = [], []
        Geoname::SYNONYMS.each do |batch_str|
          first_synonym, remainder = batch_str.strip.gsub(/ ?, ?/, ',').split(',', 2)
          @first_synonyms << first_synonym
          remainder.split(',').each do |synonym|
            geonames << {type: 'geoname', location: "#{synonym} City", state: 'CA', geo: {lat: rand * 180, lon: rand * 180}}
          end
        end
        Geoname.import geonames
      end

      it 'should find the matches' do
        @first_synonyms.each do |synonym|
          geo_hash = Geoname.geocode(location: "#{synonym} City", state: 'CA')
          geo_hash[:lat].should be_kind_of(Numeric)
          geo_hash[:lon].should be_kind_of(Numeric)
        end
      end
    end
  end

  describe '.import(geonames)' do
    it 'should set the document ID' do
      Geoname.import [{type: 'geoname', location: "Someplace", state: 'XY', geo: {lat: 12.34, lon: -123.45}}]
      Geoname.import [{type: 'geoname', location: "Someplace", state: 'XY', geo: {lat: 92.34, lon: 23.45}}]
      search = Geoname.search_for(location: 'Someplace', state: 'XY', size: 2)
      search.results.total.should == 1
      search.results.first.id.should == 'Someplace:XY'
      search.results.first.geo.lat.should == 92.34
    end
  end

end