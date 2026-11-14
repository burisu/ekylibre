# frozen_string_literal: true

module Ekylibre
  module Middleware
    # Replaces the turnout gem.
    #
    # Enable maintenance with `bin/rails maintenance:start` (creates tmp/maintenance.yml),
    # disable it with `bin/rails maintenance:end`. While the file exists, every request
    # receives a 503 with public/maintenance(.<locale>).html.
    # Optional `allowed_ips:` key in the YAML file lets some clients through.
    class Maintenance
      FLAG = 'tmp/maintenance.yml'

      def self.flag_path
        Rails.root.join(FLAG)
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        path = self.class.flag_path
        return @app.call(env) unless path.exist?

        settings = (YAML.safe_load(path.read) rescue nil) || {}
        request = Rack::Request.new(env)
        return @app.call(env) if Array(settings['allowed_ips']).include?(request.ip)

        [503, { 'content-type' => 'text/html; charset=utf-8', 'retry-after' => '3600' }, [page(request)]]
      end

      private

        def page(request)
          fra = request.get_header('HTTP_ACCEPT_LANGUAGE').to_s.start_with?('fr')
          file = Rails.public_path.join(fra ? 'maintenance.fra.html' : 'maintenance.html')
          file = Rails.public_path.join('maintenance.html') unless file.exist?
          file.read
        end
    end
  end
end
