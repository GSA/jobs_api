require 'spec_helper'

describe Agencies do

  describe '.find_organization_ids(org)' do
    context 'when Agency API finds the agency' do
      before do
        JSON.stub!(:parse).and_return({'organization_codes' => ['FOOO','BAR'] })
      end

      it 'should return the organization ID codes' do
        Agencies.find_organization_ids('foo').should == ['FOOO','BAR']
      end
    end

    context 'when Agency API does not find the agency' do
      before do
        JSON.stub!(:parse).and_return({'error' => 'No matching agency could be found.' })
      end

      it 'should return nil' do
        Agencies.find_organization_ids('foo').should be_nil
      end
    end

    context 'when Agency API raises some error' do
      before do
        JSON.stub!(:parse).and_raise Exception
      end

      it 'should return nil' do
        Agencies.find_organization_ids('foo').should be_nil
      end
    end
  end
end