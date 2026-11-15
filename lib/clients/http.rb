# frozen_string_literal: true

require 'faraday'

module Clients
  # Thin wrapper around Faraday used by every external API client.
  # HTTP errors (4xx/5xx) raise Clients::Http::Error (a Faraday::Error).
  module Http
    Error = Faraday::Error

    class << self
      def connection(timeout: 60)
        Faraday.new do |f|
          f.response :raise_error
          f.response :logger, Rails.logger, headers: false, bodies: false if defined?(Rails)
          f.options.timeout = timeout
          f.options.open_timeout = 15
        end
      end

      def get(url, params: nil, headers: {}, timeout: 60)
        connection(timeout: timeout).get(url, params, headers)
      end

      def post(url, body, headers: {}, timeout: 60)
        connection(timeout: timeout).post(url, body, headers)
      end

      # @return [Integer, nil] HTTP status carried by a Faraday error
      def status(error)
        error.respond_to?(:response_status) ? error.response_status : nil
      end

      # @return [String, nil] requested URL carried by a Faraday error
      def url(error)
        error.response&.dig(:request, :url)&.to_s
      end
    end
  end
end
