require 'test_helper'

# Behaviours kept while replacing enumerize, Sidekiq, Paperclip, the SVF code
# generator... during the Rails 8.1 upgrade
class UpgradeBehavioursTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'enumerated attributes keep the enumerize API' do
    attribute = Intervention.nature
    assert_equal %w[request record], attribute.values
    assert_equal attribute.values.map { |value| [value.text, value.to_s] }, attribute.options
    assert_equal 'record', attribute.default_value

    intervention = Intervention.new
    assert_equal 'record', intervention.nature, 'Default value applies to new records'
    assert intervention.nature == :record, 'Values compare with symbols'
    assert intervention.nature.record?
    refute intervention.nature.request?
    assert intervention.nature.text.present?
    assert_equal intervention.nature.text, intervention.nature.localize, 'Page titles (t3e) localize enum values'
    assert intervention.record?, 'Predicates are defined on the record'

    intervention.nature = :unknown
    refute intervention.valid?
    assert intervention.errors[:nature].any?

    assert Intervention.with_nature(:record).to_sql.include?('nature')
  end

  test 'enum defaults apply to persisted records with nil values' do
    tracking = Tracking.first
    Tracking.where(id: tracking.id).update_all(usage_limit_nature: nil)
    assert_equal 'no_limit', Tracking.find(tracking.id).usage_limit_nature
  end

  test 'refers_to attributes are validated against the nomenclature' do
    issue = Issue.first
    issue.nature = 'not_an_issue_nature'
    refute issue.valid?
    assert issue.errors[:nature].any?
    issue.nature = Onoma::IssueNature.all.first
    issue.valid?
    assert issue.errors[:nature].empty?

    # Unknown values already stored are not checked (as with enumerize)
    product = Product.where(derivative_of: nil).first
    Product.where(id: product.id).update_all(derivative_of: 'unknown_variety')
    stored = Product.find(product.id)
    stored.valid?
    assert stored.errors[:derivative_of].empty?
    stored.derivative_of = 'another_unknown_variety'
    stored.valid?
    assert stored.errors[:derivative_of].any?, 'Assigned unknown values are invalid'
  end

  test 'update_all keeps lock_version and works with joins' do
    sale = Sale.first
    version = sale.lock_version
    Sale.where(id: sale.id).update_all(description: 'Updated')
    assert_equal version, sale.reload.lock_version
    assert_nothing_raised do
      SaleItem.joins(:sale).where(sale_id: sale.id).where('unit_pretax_amount IS NOT NULL').update_all(annotation: 'Joined')
    end
  end

  test 'protected records cannot be destroyed even without changes' do
    document = Document.create!(name: 'Kept', mandatory: true, file: File.open(Rails.root.join('Gemfile')))
    assert_raises(Ekylibre::Record::RecordNotDestroyable) { document.destroy! }
    document.update_columns(mandatory: false)
    assert_nothing_raised { document.destroy! }
  end

  test 'jobs run in the tenant they were enqueued in' do
    job = DailyTriggerJob.new
    assert_equal Ekylibre::Tenant.current, job.serialize['tenant']
    restored = DailyTriggerJob.new
    restored.deserialize(job.serialize)
    assert_equal Ekylibre::Tenant.current, restored.tenant
  end

  test 'task status is shared and merged' do
    Ekylibre::TaskStatus.delete('test:status')
    Ekylibre::TaskStatus.update('test:status', status: 'running', step: 1)
    Ekylibre::TaskStatus.update('test:status', message: 'Half')
    assert_equal({ 'status' => 'running', 'step' => '1', 'message' => 'Half' }, Ekylibre::TaskStatus.read('test:status'))
    Ekylibre::TaskStatus.delete('test:status')
    assert_equal({}, Ekylibre::TaskStatus.read('test:status'))
  end

  test 'SVF files are parsed and rebuilt from their norm' do
    file = fixture_files_path.join('imports', 'isagri', 'isapaye', 'ecr_journal_entries.ecr')
    data = SVF::Isapaye.parse(file)
    assert data.folder.entries.any?
    content = data.to_s
    rebuilt = Tempfile.new(['isapaye', '.ecr'], binmode: true)
    rebuilt.write(content.encode('ISO-8859-15', invalid: :replace, undef: :replace))
    rebuilt.close
    assert_equal content, SVF::Isapaye.parse(rebuilt.path).to_s
    assert_raises(SVF::InvalidSyntax) do
      broken = Tempfile.new(['broken', '.ecr'])
      # Invalid date (month 13) in the entry
      broken.write("VER   #{' ' * 43}\nDOS   12345678\nECR   AA31139999#{' ' * 40}\n")
      broken.close
      SVF::Isapaye.parse(broken.path)
    end
  end

  test 'aggregators are registered classes' do
    assert_equal %w[animal_husbandry_register veterinary_booklet], Aggeratio.names.sort
    assert_equal Aggeratio::VeterinaryBooklet, Aggeratio['veterinary_booklet']
    assert Aggeratio.of_category(Aggeratio::VeterinaryBooklet.category).include?(Aggeratio::VeterinaryBooklet)
  end

  test 'helpers using concat in blocks render inside their tag from Haml templates' do
    view = ApplicationController.new.view_context
    view.define_singleton_method(:inner) do
      content_tag(:div, nil, class: 'in') do
        concat(content_tag(:i, nil, class: 'ic'))
        concat(content_tag(:span, 'txt'))
      end
    end
    expected = '<div class="in"><i class="ic"></i><span>txt</span></div>'
    assert_equal expected, view.render(inline: "= inner\n", type: :haml).strip
    nested = view.render(inline: "= content_tag(:div, nil, class: 'outer') do\n  = inner\n", type: :haml)
    assert_equal %(<div class="outer">#{expected}\n</div>), nested.strip
    assert_equal '<p>a<b>b</b></p>', view.render(inline: "<%= content_tag(:p) { concat('a'); concat(content_tag(:b, 'b')) } %>")
  end

  test 'framework behaviours of Rails 5.2 are kept despite Rails 8.1 defaults' do
    view = ApplicationController.new.view_context
    assert_includes view.button_to('Go', '/x'), '<input type="submit"', 'button_to renders an input'
    assert_includes view.stylesheet_link_tag('/x.css'), 'media="screen"', 'stylesheets stay screen-only'
    assert_includes view.form_tag('/x', method: :get), 'name="utf8"', 'forms keep the utf8 field'
    refute ActiveRecord.run_after_transaction_callbacks_in_order_defined
    assert_equal :log, ActionController::Base.action_on_open_redirect, 'redirections to other hosts are allowed'

    # Readonly attributes are ignored on assignment, not raised
    item = SaleItem.first
    assert_nothing_raised { item.currency = 'XXX' } if SaleItem.readonly_attribute?('currency')

    # New records do not set the inverse of has_many associations
    intervention = Intervention.new
    parameter = intervention.inputs.build
    assert_nil parameter.association(:intervention).target if parameter.respond_to?(:intervention) && !Intervention.reflect_on_association(:inputs).options[:inverse_of]
  end

  test 'empty sums of amounts stay decimal as with Rails 5.2' do
    empty = JournalEntryItem.where(id: -1)
    assert_equal BigDecimal(0), empty.sum('real_debit - real_credit')
    assert_kind_of BigDecimal, empty.sum('real_debit - real_credit')
    assert_kind_of BigDecimal, empty.sum(:real_debit)
    assert_equal 0, Intervention.where(id: -1).sum(:id), 'Integer columns keep integer sums'
    assert_kind_of Integer, Intervention.where(id: -1).sum(:id)
    I18n.with_locale(:fra) do
      assert_equal BigDecimal(0).l(currency: 'EUR'), empty.sum('real_credit - real_debit').l(currency: 'EUR')
      assert_match(/0,00/, empty.sum('real_credit - real_debit').l(currency: 'EUR'))
    end
  end
end
