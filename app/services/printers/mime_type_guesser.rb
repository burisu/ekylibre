# frozen_string_literal: true

module Printers
  class MimeTypeGuesser
    def guess(file)
      Marcel::MimeType.for(file)
    end
  end
end
