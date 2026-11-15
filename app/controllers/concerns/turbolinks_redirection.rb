# frozen_string_literal: true

# Server side of Turbolinks 5 (formerly the turbolinks gem):
# - redirections of XHR non-GET requests are answered with a Turbolinks visit
#   so remote forms and links follow them;
# - redirections during a Turbolinks visit tell Turbolinks the final location.
module TurbolinksRedirection
  extend ActiveSupport::Concern

  included do
    before_action :set_turbolinks_location_header_from_session
  end

  def redirect_to(url = {}, options = {})
    turbolinks = options.delete(:turbolinks)

    super.tap do
      if turbolinks != false && request.xhr? && !request.get?
        visit_location_with_turbolinks(location, turbolinks)
      elsif request.headers['Turbolinks-Referrer']
        session[:_turbolinks_location] = location
      end
    end
  end

  private

    def visit_location_with_turbolinks(location, action)
      visit_options = { action: action.to_s == 'advance' ? action : 'replace' }

      self.status = 200
      response.headers['X-Xhr-Redirect'] = location
      response.delete_header('Location')
      self.content_type = 'text/javascript'
      self.response_body = "Turbolinks.clearCache()\nTurbolinks.visit(#{location.to_json}, #{visit_options.to_json})"
    end

    def set_turbolinks_location_header_from_session
      if (location = session.delete(:_turbolinks_location))
        response.headers['Turbolinks-Location'] = location
      end
    end
end
