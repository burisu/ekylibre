module Onoma
  class Indicator < Onoma::Record::Base
    class << self
      delegate :each, to: :all
    end
  end
end
