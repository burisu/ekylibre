module Ekylibre
  module Reporting
    FORMATS = %w[pdf].freeze

    # Returns the list of formats used by default for the reporting.
    # The default format is the first.
    def self.formats
      FORMATS
    end
  end
end
