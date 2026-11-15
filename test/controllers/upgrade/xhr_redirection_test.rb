require 'test_helper'

module Upgrade
  # Redirections of remote (jquery_ujs) non-GET requests are followed with a
  # Turbo visit, like the turbolinks gem did with Turbolinks
  class XhrRedirectionTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::TeamsController

    setup do
      sign_in(create(:user))
      @team = Team.first
    end

    test 'XHR update redirection is answered with a Turbo visit' do
      patch :update, xhr: true, params: { id: @team.id, team: { name: 'Remote team' } }
      assert_response :success
      assert_equal 'text/javascript', response.media_type
      assert_match(/Turbo\.visit\(".+", \{"action":"replace"\}\)/, response.body)
      assert response.headers['X-Xhr-Redirect'].present?
      assert_nil response.headers['Location']
      assert_equal 'Remote team', @team.reload.name
    end

    test 'normal update redirection is unchanged' do
      patch :update, params: { id: @team.id, team: { name: 'Normal team' } }
      assert_response :redirect
      assert_nil response.headers['X-Xhr-Redirect']
    end

    test 'XHR GET requests are not changed' do
      get :edit, xhr: true, params: { id: @team.id }
      refute_match(/Turbo\.visit/, response.body)
    end
  end
end
