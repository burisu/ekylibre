module ActiveExchanger
  class Error < ::StandardError
  end

  class NotSupportedFormatError < Error
  end

  class NotWellFormedFileError < Error
  end

  class IncompatibleDataError < Error
  end

  class InvalidDataError < Error
  end
end

