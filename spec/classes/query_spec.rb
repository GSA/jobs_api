require 'spec_helper'

describe Query do
  describe '.new(query, organization_ids)' do
    context 'when query phrase contains the year or irrelevant words/characters' do
      before do
        Agencies.stub!(:find_organization_ids)
      end

      let(:query) { Query.new("  FUN, summer #{Date.current.year} i.t. job opportunity descriptions    available in miami,, fl", nil) }

      it 'should normalize the query phrase' do
        query.keywords.should == 'fun summer it'
      end
    end

    context 'when city and valid state are passed in before/after job token' do
      let(:query_strings) { ["jobs fulton md", "fulton maryland jobs", "jobs in fulton, md"] }
      it 'should set both city and state' do
        query_strings.each do |str|
          query = Query.new(str, nil)
          query.location.state.should == 'MD'
          query.location.city.should == 'fulton'
          query.keywords.should be_blank
        end
      end
    end

    context 'when city/state and job title surround job token' do
      let(:query_strings) { ["fulton maryland jobs nursing", "nursing jobs fulton md"] }
      it 'should set both city and state' do
        query_strings.each do |str|
          query = Query.new(str, nil)
          query.location.state.should == 'MD'
          query.location.city.should == 'fulton'
          query.keywords.should == "nursing"
        end
      end
    end

    context 'when seasonal/internship job specified in query' do
      it 'should set position_offering_type_code' do
        Query.new('intern jobs', nil).position_offering_type_code.should == 15328
        Query.new('internship jobs', nil).position_offering_type_code.should == 15328
        Query.new('park ranger seasonal jobs', nil).position_offering_type_code.should == 15322
      end

      it 'should remove the phrase from the query' do
        Query.new('intern jobs', nil).keywords.should be_blank
        Query.new('park ranger seasonal jobs', nil).keywords.should == 'park ranger'
      end
    end

    context 'when full/part-time job specified in query' do
      it 'should set position_schedule_type_code' do
        Query.new('part-time jobs', nil).position_schedule_type_code.should == 2
        Query.new('full time jobs', nil).position_schedule_type_code.should == 1
      end

      it 'should remove the phrase from the query' do
        Agencies.should_receive(:find_organization_ids).with('tsa').and_return ['HSBC']
        Query.new('part-time tsa jobs', nil).keywords.should be_blank
      end
    end

    context 'when volunteer job specified in query' do
      it 'should set rate_interval_code to WC (i.e., without compensation)' do
        Query.new('volunteer jobs', nil).rate_interval_code.should == 'WC'
        Query.new('volunteering jobs', nil).rate_interval_code.should == 'WC'
      end

      it 'should remove the phrase from the query' do
        Query.new('volunteer jobs', nil).keywords.should be_blank
      end
    end

    context 'when organization_ids param is not passed in' do
      context "when query has both organization and location specified in query" do
        before do
          Agencies.stub!(:find_organization_ids).with('cia').and_return ['CI00']
        end

        let(:queries) { ['jobs at the cia in miami fl', 'jobs with the cia in miami fl', 'jobs in miami fl at the cia', 'jobs in miami fl with the cia'] }
        it 'should create an Organization and a Location' do
          queries.each do |query_str|
            query = Query.new(query_str, nil)
            query.location.city.should == 'miami'
            query.location.state.should == 'FL'
            query.organization_ids.should == ['CI00']
            query.keywords.should be_blank
          end
        end
      end

      context "when query is of form 'jobs (at|with) (.*)'" do
        before do
          Agencies.stub!(:find_organization_ids).with('cia').and_return ['CI00']
        end

        let(:queries) { ['jobs at the cia', 'jobs with the cia'] }
        it 'should create an Organization' do
          queries.each do |query_str|
            query = Query.new(query_str, nil)
            query.organization_ids.should == ['CI00']
            query.location.should be_nil
            query.keywords.should be_blank
          end
        end
      end

      context 'when query is just a vague job-related phrase' do
        it 'should strip out the non-essential words' do
          Query.new('jobs and employment', nil).keywords.should_not be_present
          Query.new('career opportunities', nil).keywords.should_not be_present
          Query.new('job openings', nil).keywords.should_not be_present
          Query.new('puestos', nil).keywords.should_not be_present
        end
      end

      context 'when some job-related keyword is preceeded/followed by some non-location, non-organization text' do
        before do
          Agencies.stub!(:find_organization_ids)
        end

        it 'should strip the keyword from the resulting query keyword text' do
          %w{position job opening posting opportunity vacancy employment}.each do |job_keyword|
            [job_keyword, job_keyword.pluralize].each do |variant|
              Query.new("fun summer #{variant}", nil).keywords.should == 'fun summer'
              Query.new("#{variant} security", nil).keywords.should == 'security'
            end
          end
        end

        context 'when the preceeding/following text is a valid organization' do
          before do
            Agencies.stub!(:find_organization_ids).with('tsa').and_return ['ABCD']
          end

          it 'should extract an organization out of it' do
            query = Query.new('tsa job openings', nil)
            query.organization_ids.should == ['ABCD']
            query.keywords.should be_blank
            query = Query.new('jobs tsa', nil)
            query.organization_ids.should == ['ABCD']
            query.keywords.should be_blank
          end
        end

        context 'when the preceeding/following text is neither an organization nor a location' do
          it 'should use that text for fulltext search' do
            query = Query.new('fun summer jobs', nil)
            query.organization_ids.should be_nil
            query.keywords.should == 'fun summer'
            query = Query.new('jobs data', nil)
            query.organization_ids.should be_nil
            query.keywords.should == 'data'
          end
        end
      end
    end

    context 'when organization_ids param passed in' do
      context 'when different organization specified in query' do
        before do
          Agencies.should_receive(:find_organization_ids).with('tsa').and_return ['ABCD']
        end

        let(:query) { Query.new('tsa jobs', ['DD00']) }

        it 'should override organization_ids param' do
          query.organization_ids.should == ['ABCD']
        end
      end

      context 'when no organization specified in query' do
        before do
          Agencies.stub!(:find_organization_ids)
        end

        let(:query) { Query.new('fun jobs', ['dd00', 'abcd']) }

        it 'should set capitalized organization_ids from param' do
          query.organization_ids.should == ['DD00', 'ABCD']
        end
      end

      context 'when query is not present' do
        let(:query) { Query.new(nil, ['DD00']) }

        it 'should set capitalized organization_ids from param' do
          query.organization_ids.should == ['DD00']
        end
      end
    end

    context "when query and organization_ids aren't present" do
      let(:query) { Query.new(nil, nil) }

      it 'should not be valid' do
        query.valid?.should be_false
      end
    end
  end

  describe '#organization_prefixes' do
    it 'should return org codes that are 2 chars long' do
      Query.new('jobs', ['AB', 'CDEF', 'AF', 'A123']).organization_prefixes.should == %w(AB AF)
    end
  end

  describe '#organization_terms' do
    it 'should return org codes that are > 2 chars long' do
      Query.new('jobs', ['AB', 'CDEF', 'AF', 'A123']).organization_terms.should == %w(CDEF A123)
    end
  end
end