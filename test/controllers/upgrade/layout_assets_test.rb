require 'test_helper'

module Upgrade
  # Pages load their assets with Propshaft, import maps and Dart Sass (no
  # Sprockets, Webpacker nor Node.js), in the order the legacy scripts need
  class LayoutAssetsTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::DashboardsController

    setup do
      sign_in(create(:user))
    end

    test 'backend layout loads modules, legacy scripts and theme' do
      get :home
      assert_response :success
      body = response.body

      assert_includes body, 'window.EkylibreAssets'
      assert_select 'script[type=importmap]', 1
      assert_includes body, 'import "application"'
      assert_includes body, 'import "legacy_globals"'
      assert_select 'link[rel=stylesheet][href*="themes/tekyla/all"]'

      legacy = css_select('script[src][defer]').map { |script| script['src'] }
      assert legacy.any? { |src| src.include?('legacy/jquery-rails/jquery') }, 'jQuery must be loaded as a legacy script'
      assert legacy.index { |src| src.include?('legacy/jquery-rails/jquery') } < legacy.index { |src| src.include?('legacy_setup') },
             'Legacy scripts must keep the Sprockets order'

      # Modules and globals run before the deferred legacy scripts
      assert body.index('import "legacy_globals"') < body.index(legacy.first)
      refute_includes body, '/packs/'
      refute_match(/turbolinks/i, body)
    end

    test 'every legacy script of the manifest is served' do
      JavascriptsHelper::LEGACY_JAVASCRIPTS.each do |path|
        assert Rails.application.assets.load_path.find(path), "Missing legacy script #{path}"
      end
    end

    test 'every theme compiles with Dart Sass' do
      Ekylibre::Application.instance.themes.each do |theme|
        source = Rails.root.join('app', 'assets', 'stylesheets', 'themes', theme.name, 'all.scss')
        css, error, status = Open3.capture3('bundle', 'exec', 'dartsass', '--quiet', '--no-source-map',
                                            *Rails.application.config.dartsass.build_options.grep(/\A--load-path=/),
                                            source.to_s)
        assert status.success?, "Theme #{theme.name} does not compile: #{error.lines.first(5).join}"
        # Rules of the stylesheets formerly provided by gems (cartography, agric…)
        assert_includes css, '.marker-origin', "Theme #{theme.name} misses the cartography rules"
      end
    end

    test 'images used by JavaScript are digested assets' do
      JavascriptsHelper::JAVASCRIPT_ASSETS.each do |path|
        assert Rails.application.assets.load_path.find(path), "Missing image #{path}"
      end
    end
  end
end
