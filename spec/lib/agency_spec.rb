require 'rails_helper'

describe Agencies do

  describe '.find_organization_ids(org)' do
    context 'when Agency API finds the agency' do
      before do
        allow(JSON).to receive(:parse).and_return({'organization_codes' => ['FOOO','BAR'] })
      end

      it 'should return the organization ID codes' do
        expect(Agencies.find_organization_ids('foo')).to eq(['FOOO','BAR'])
      end
    end

    context 'when Agency API does not find the agency' do
      before do
        allow(JSON).to receive(:parse).and_return({'error' => 'No matching agency could be found.' })
      end

      it 'should return nil' do
        expect(Agencies.find_organization_ids('foo')).to be_nil
      end
    end

    context 'when Agency API raises some error' do
      before do
        allow(JSON).to receive(:parse).and_raise Exception
      end

      it 'should return nil' do
        expect(Agencies.find_organization_ids('foo')).to be_nil
      end
    end
  end
end
