require 'rails_helper'

describe ApiConstraint do
  describe '#matches?' do
    context 'when request header does not contain Accept on non default constraint' do
      it 'should return false' do
        constraint = ApiConstraint.new(version: 1, default: false)
        request = double('request', headers: {})
        expect(constraint.matches?(request)).to be_falsey
      end
    end
  end
end
