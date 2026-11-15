require 'test_helper'

module Upgrade
  # Screens whose code changed during the upgrade
  class EntityMovesTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::EntitiesController

    setup do
      sign_in(create(:user))
    end

    test 'entity journal entry items are listed with their totals, with and without search' do
      entity = Entity.where.not(client_account_id: nil).first
      get :show, params: { id: entity.id }
      assert_response :success
      get :show, params: { id: entity.id, b: 'abc' }
      assert_response :success
    end

    test 'entity moves conditions keep the account and the search' do
      entity = Entity.where.not(client_account_id: nil).first
      @controller.params = ActionController::Parameters.new(b: 'foo bar')
      conditions = @controller.send(:entity_moves_conditions, entity.client_account_id)
      assert_includes conditions.first, 'account_id = ?'
      assert_equal entity.client_account_id, conditions.last
      assert_includes conditions, '%foo%'
      assert_includes conditions, '%bar%'
      assert JournalEntryItem.joins(:entry).where(conditions).to_a
    end
  end

  class SubscriptionsFilterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::SubscriptionsController

    setup do
      sign_in(create(:user))
    end

    test 'subscriptions can be filtered by date' do
      get :index, params: { subscribed_on: '2016-01-01' }
      assert_response :success
      get :list, params: { subscribed_on: '2016-01-01' }
      assert_response :success
      get :list, params: { subscribed_on: 'not a date' }
      assert_response :success
    end
  end

  class EmailTemplatesEditorTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::EmailTemplatesController

    setup do
      sign_in(create(:user))
      EmailTemplate.load_defaults
    end

    test 'email template body is edited with the self-hosted TinyMCE' do
      template = EmailTemplate.first
      skip 'No default email template' unless template

      get :edit, params: { id: template.id }
      assert_response :success
      assert_select 'script[src="/vendor/tinymce/tinymce.js"]'
      assert_includes response.body, "tinymce.init("
      assert File.exist?(Rails.root.join('public', 'vendor', 'tinymce', 'tinymce.js'))
    end
  end

  class DeliveriesParcelsTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::DeliveriesController

    setup do
      sign_in(create(:user))
    end

    test 'delivery form lists its parcels and the available ones' do
      delivery = Delivery.first
      get :edit, params: { id: delivery.id }
      assert_response :success
      parcels = delivery.available_parcels.to_a
      assert parcels.all? { |parcel| parcel.delivery_id == delivery.id || (parcel.delivery_id.nil? && parcel.state != 'given') }
      assert_equal delivery.parcels.order(:number).to_a, parcels.select { |parcel| parcel.delivery_id == delivery.id }
    end

    test 'a new delivery only offers parcels not given yet' do
      given = Parcel.where(delivery_id: nil).first || Parcel.first
      given.update_columns(delivery_id: nil, state: 'given')
      parcels = Delivery.new.available_parcels.to_a
      refute_includes parcels, given
      assert parcels.all? { |parcel| parcel.delivery_id.nil? && parcel.state != 'given' }
      get :new
      assert_response :success
    end
  end

  # Page titles show translated enumerated values (Enumerize::Value#localize)
  class IdentifierTitleTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::IdentifiersController

    setup do
      sign_in(create(:user))
    end

    test 'title shows the human name of the nature' do
      identifier = Identifier.first
      get :show, params: { id: identifier.id, locale: 'eng' }
      assert_response :success
      title = css_select('title').text
      assert_includes title, identifier.nature.text
      refute_includes title, ": #{identifier.nature}" unless identifier.nature.text == identifier.nature.to_s
    end
  end

  # Empty amounts are shown with decimals ("0,00 €"), as with Rails 5.2
  class AssociateBalanceTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::AssociatesController

    setup do
      sign_in(create(:user))
    end

    test 'balance of an associate without entries keeps decimals' do
      associate = Associate.first
      skip 'No associate fixture' unless associate
      get :show, params: { id: associate.id, locale: 'eng' }
      assert_response :success
      assert_select 'span.value', text: /\d[.,]\d{2}/
    end
  end

  # Grids keep the wice_grid markup, pagination and status
  class SimpleGridTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::NamingFormatsController

    setup do
      sign_in(create(:user))
    end

    test 'grid keeps the wice_grid container, footer and row classes' do
      get :index
      assert_response :success
      count = NamingFormat.count
      assert_select 'div.wice-grid-container.table-responsive#grid[data-grid-name=grid]' do
        assert_select 'div#grid_title'
        assert_select 'table.table-striped.table-bordered.table.wice-grid.naming-formats-list' do
          assert_select 'thead tr.wice-grid-title-row th'
          assert_select 'tfoot .pagination_status', text: count.zero? ? '0' : "1-#{count} / #{count}"
          assert_select 'tbody tr.odd', count.positive? ? 1.. : 0
        end
      end
    end

    test 'grids are paginated by 20 records like wice_grid' do
      relation = [Entity, Product, JournalEntryItem].map { |model| model.order(:id) }.detect { |r| r.count > 20 }
      skip 'Not enough records' unless relation
      grid = SimpleGrid::Grid.new(relation, params: ActionController::Parameters.new({}))
      assert_equal 20, grid.resultset.size
      assert_equal relation.count, grid.total_count
      second = SimpleGrid::Grid.new(relation, params: ActionController::Parameters.new(grid: { page: '2' }))
      assert_equal relation.offset(20).first, second.resultset.first
      all = SimpleGrid::Grid.new(relation, params: ActionController::Parameters.new(grid: { pp: relation.count.to_s }))
      assert all.all_record_mode?
      assert_equal relation.count, all.resultset.size
    end
  end
end
