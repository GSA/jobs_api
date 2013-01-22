require 'spec_helper'

describe Agencies do

  describe '.find_organization_id(org)' do
    context 'when Agency API finds the agency' do
      before do
        JSON.stub!(:parse).and_return({'organization_code' => 'FOOO' })
      end

      it 'should return the organization ID code' do
        Agencies.find_organization_id('foo').should == 'FOOO'
      end
    end

    context 'when Agency API does not find the agency' do
      before do
        JSON.stub!(:parse).and_return({'error' => 'No matching agency could be found.' })
      end

      it 'should return nil' do
        Agencies.find_organization_id('foo').should be_nil
      end
    end

    context 'when Agency API raises some error' do
      before do
        JSON.stub!(:parse).and_raise Exception
      end

      it 'should return nil' do
        Agencies.find_organization_id('foo').should be_nil
      end
    end
  end
end