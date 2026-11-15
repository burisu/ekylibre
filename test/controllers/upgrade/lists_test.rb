require 'test_helper'

module Upgrade
  # Lists rendered by the in-app ActiveList engine behave like the former
  # active_list gem: same translations, same user preferences
  class ListsTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::EntitiesController

    # Value saved by the active_list gem (whole params dumped with objects)
    LEGACY_PREFERENCE = <<~YAML.freeze
      ---
      sort: last_name
      dir: desc
      only: content
      action: list
      controller: backend/entities
      hidden_columns:
      - :number
      page: 1
      per_page: 20
      content_for: !ruby/object:ActionController::Parameters
        parameters: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
          actions: main_toolbar
          pagination: meta_toolbar
        permitted: false
    YAML

    setup do
      @user = create(:user)
      sign_in(@user)
    end

    test 'list labels are translated' do
      %i[eng fra].each do |locale|
        I18n.with_locale(locale) do
          %w[list.pagination.x_to_y_of_total list.pagination.next list.pagination.previous list.items_per_page
             list.columns list.menu list.no_records list.export_as list.export.formats.csv].each do |key|
            assert I18n.exists?(key, locale), "Missing #{locale} translation for #{key}"
          end
        end
      end

      get :index, params: { locale: 'eng' }
      assert_response :success
      refute_includes response.body, 'translation missing'
      refute_includes response.body, 'Translation missing'
    end

    test 'preferences saved by the active_list gem are kept' do
      @user.preference('list._entities_list_entities_tag', YAML.dump({})).set!(LEGACY_PREFERENCE)

      get :list
      assert_response :success
      assert_select 'li[data-list-toggle-column=mail_line_1].checked', 1,
                    'Columns hidden by default but shown by the user stay shown'
      assert_select 'li[data-list-toggle-column=number].unchecked', 1, 'Columns hidden by the user stay hidden'
      assert_select 'tbody[data-per-page="20"]'
    end

    test 'cells of columns with links keep the url class' do
      get :list
      assert_response :success
      assert_select 'tbody td.col.url a[href^="/backend/entities/"]'
    end

    test 'status lights are rendered without spaces between them' do
      @controller = Backend::ReceptionsController.new
      get :list
      assert_response :success
      assert_match %r{<span class="go"></span><span class="caution"></span><span class="stop"></span>}, response.body
    end

    test 'action links come back to the list page' do
      get :index
      assert_response :success
      assert_select 'td.act a[href*="/edit?redirect=%2Fbackend%2Fentities"]'
    end

    test 'toggling a column is saved in user preferences' do
      get :list, params: { column: 'mail_line_1', visibility: 'shown' }, xhr: true
      assert_response :success
      saved = YAML.safe_load(@user.preference('list._entities_list_entities_tag').value, permitted_classes: [Symbol])
      refute_includes saved['hidden_columns'], :mail_line_1
      assert_includes saved['hidden_columns'], :mail_country
    end
  end
end
