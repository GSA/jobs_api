class SearchDefinition
  attr_accessor :definition

  def initialize(definition = nil)
    @definition = definition || {
      query: {
        bool: {
          must: [],
          should: []
        }
      }
    }

    yield(self) if block_given?
  end

  def must(query)
    if definition[:query]
      definition[:query][:bool][:must] << query
    else
      definition[:bool][:must] << query
    end
  end

  def should(query)
    if definition[:query]
      definition[:query][:bool][:should] << query
    else
      definition[:bool][:should] << query
    end
  end

  def sort(query)
    definition[:sort] = query
  end

  def to_s
    definition
  end
end
