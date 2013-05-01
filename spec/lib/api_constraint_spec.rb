require 'spec_helper'

describe ApiConstraint do
  describe '#matches?' do
    context 'when request header does not contain Accept on non default constraint' do
      it 'should return false' do
        constraint = ApiConstraint.new(version: 1, default: false)
        request = mock('request', headers: {})
        constraint.matches?(request).should be_false
      end
    end
  end
end