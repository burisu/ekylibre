# frozen_string_literal: true

# Redirections of XHR non-GET requests (jquery_ujs remote forms and links)
# are answered with a Turbo visit, so the browser follows them. The location
# is also given in the X-Xhr-Redirect header for JavaScript callers.
module XhrRedirection
  def redirect_to(url = {}, options = {})
    turbo = options.delete(:turbo)

    super.tap do
      visit_location_with_turbo(location, turbo) if turbo != false && request.xhr? && !request.get?
    end
  end

  private

    def visit_location_with_turbo(location, action)
      visit_options = { action: action.to_s == 'advance' ? 'advance' : 'replace' }

      self.status = 200
      response.headers['X-Xhr-Redirect'] = location
      response.delete_header('Location')
      self.content_type = 'text/javascript'
      self.response_body = "Turbo.cache.clear()\nTurbo.visit(#{location.to_json}, #{visit_options.to_json})"
    end
end
