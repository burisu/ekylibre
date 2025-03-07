# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class SalesController < Backend::BaseController
    manage_restfully except: %i[index show new], redirect_to: '{action: :show, id: "id".c}'.c, continue: [:nature_id]

    respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json

    before_action :save_search_preference, only: :index

    unroll :number, :amount, :currency, :created_at, client: :full_name

    # management -> sales_conditions
    def self.sales_conditions
      code = search_conditions(sales: %i[pretax_amount amount reference_number number initial_number description], entities: %i[number full_name]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND ((#{Sale.table_name}.invoiced_at IS NULL AND #{Sale.table_name}.created_at::DATE BETWEEN ? AND ?)'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "  c[0] << ' OR (#{Sale.table_name}.invoiced_at::DATE BETWEEN ? AND ?))'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:state].is_a?(Array) && !params[:state].empty?\n"
      code << "  c[0] << ' AND #{Sale.table_name}.state IN (?)'\n"
      code << "  c << params[:state]\n"
      code << "end\n "
      code << "if params[:nature].present? && params[:nature].to_s != 'all'\n"
      code << "  if params[:nature] == 'unpaid'\n"
      code << "    c[0] << ' AND NOT #{Affair.table_name}.closed'\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:responsible_id].to_i > 0\n"
      code << "  c[0] += \" AND \#{Sale.table_name}.responsible_id = ?\"\n"
      code << "  c << params[:responsible_id]\n"
      code << "end\n"
      code << "if params[:provider].present?\n"
      code << "  c[0] += \" AND \#{Sale.table_name}.provider ->> 'vendor' = ?\"\n"
      code << "  c << params[:provider].tap { |e| e[0] = e[0].downcase }.to_s\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list(conditions: sales_conditions, selectable: true, joins: %i[client affair], order: { created_at: :desc, number: :desc }) do |t| # , :line_class => 'RECORD.tags'
      # t.action :show, url: {format: :pdf}, image: :print
      t.action :edit, if: :updateable?
      t.action :cancel, if: :cancellable?
      t.action :destroy, if: :destroyable?
      t.column :number, url: { action: :show }
      t.column :reference_number
      t.column :created_at
      t.column :invoiced_at
      t.column :client, url: true
      t.column :responsible, hidden: true
      t.column :description, hidden: true
      t.column :provider_vendor, label_method: 'provider_vendor&.capitalize', sort: :provider_vendor, hidden: true
      t.status
      t.column :state_label
      t.column :pretax_amount, currency: true, on_select: :sum
      t.column :amount, currency: true, on_select: :sum
      t.column :affair_balance, currency: true, on_select: :sum, hidden: true

    end

    # Displays the main page with the list of sales
    def index
      respond_to do |format|
        format.html
        format.xml { render xml: @sales }
        format.pdf { render pdf: @sales, with: params[:template] }
      end
    end

    list(:credits, model: :sales, conditions: { credited_sale_id: 'params[:id]'.c }, children: :items) do |t|
      t.column :number, url: true, children: :designation
      t.column :client, children: false
      t.column :created_at, children: false
      t.column :pretax_amount, currency: true
      t.column :amount, currency: true
    end

    list(:shipments, children: :items, conditions: { sale_id: 'params[:id]'.c }) do |t|
      t.column :number, children: :product_name, url: true
      t.column :delivery_mode
      t.column :delivery
      t.column :address, label_method: :coordinate, children: false
      t.status
      t.column :state, label_method: :human_state_name, hidden: true
      t.column :transporter, children: false, url: true
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
    end

    list(:subscriptions, joins: :sale, conditions: ['sales.id = ?', 'params[:id]'.c]) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :nature, url: true
      t.column :subscriber, url: true
      t.column :address
      t.column :started_on
      t.column :stopped_on
      t.column :quantity
    end

    list(:undelivered_items, model: :sale_items, conditions: { sale_id: 'params[:id]'.c }) do |t|
      t.column :name, through: :variant
      # t.column :pretax_amount, currency: true, through: :price
      t.column :quantity
      # t.column :unit
      # t.column :pretax_amount, :currency => true
      t.column :amount
      # t.column :undelivered_quantity, :datatype => :decimal
    end

    list(:items, model: :sale_items, conditions: { sale_id: 'params[:id]'.c }, order: { id: :asc }, export: false, line_class: "((RECORD.variant.subscribing? and RECORD.subscriptions.sum(:quantity) != RECORD.quantity) ? 'warning' : '')".c, include: %i[variant subscriptions]) do |t|
      # t.action :edit, if: 'RECORD.sale.draft? and RECORD.reduction_origin_id.nil? '
      # t.action :destroy, if: 'RECORD.sale.draft? and RECORD.reduction_origin_id.nil? '
      # t.column :name, through: :variant
      # t.column :position
      t.column :label
      t.column :annotation, hidden: true
      t.column :conditioning_unit
      t.column :conditioning_quantity, class: 'right-align'
      t.column :unit_pretax_amount, currency: true, class: 'right-align'
      t.column :unit_amount, currency: true, hidden: true, class: 'right-align'
      t.column :base_unit_amount, currency: true, hidden: true, class: "right-align default-unit-amount hidden"
      t.column :reduction_percentage, class: 'right-align'
      t.column :tax, url: true, hidden: true, class: 'right-align'
      t.column :pretax_amount, currency: true, class: 'right-align'
      t.column :amount, currency: true, class: 'right-align'
      t.column :activity_budget, hidden: true, class: 'right-align'
      t.column :team, hidden: true, class: 'right-align'
    end

    # Displays details of one sale selected with +params[:id]+
    def show
      return unless @sale = find_and_check

      @sale.other_deals

      respond_to do |format|
        format.pdf do
          document_template = DocumentTemplate.find(params[:template])

          if document_template.file_extension.odt?
            generate_n_send_pdf_for(@sale, document_template) || redirect_to_back(fallback_location: backend_sale_path(@sale))
          else
            create_response
          end
        end

        format.xml do
          create_response
        end

        format.html do
          t3e @sale.attributes, client: @sale.client.full_name, state: @sale.state_label, label: @sale.label
          create_response
        end
      end
    end

    def new
      unless nature = SaleNature.find_by(id: params[:nature_id]) || SaleNature.by_default
        notify_error :need_a_valid_sale_nature_to_start_new_sale
        redirect_to action: :index
        return
      end
      @sale = if params[:intervention_ids]
                Intervention.convert_to_sale(params[:intervention_ids])
              else
                Sale.new(nature: nature)
              end
      @sale.currency = @sale.nature.currency
      if client = Entity.find_by(id: @sale.client_id || params[:client_id] || params[:entity_id] || session[:current_entity_id])
        if client.default_mail_address
          cid = client.default_mail_address.id
          @sale.attributes = { address_id: cid, delivery_address_id: cid, invoice_address_id: cid }
        end
      end
      session[:current_entity_id] = (client ? client.id : nil)
      @sale.responsible = current_user.person
      @sale.client_id = session[:current_entity_id]
      @sale.letter_format = false
      @sale.function_title = :default_letter_function_title.tl
      @sale.introduction = :default_letter_introduction.tl
      @sale.conclusion = :default_letter_conclusion.tl
      @sale.items_attributes = params[:items_attributes] if params[:items_attributes]
      @sale.payment_delay = nature.payment_delay
      if params[:fixed_asset_id]
        fixed_asset = FixedAsset.find(params[:fixed_asset_id])
        product = fixed_asset.product
        item_properties = product ? { variant: product.variant, quantity: 1 } : {}
        @sale.items.build({ fixed: true, preexisting_asset: true, fixed_asset: fixed_asset }.merge(item_properties))
      end
      render locals: { with_continue: true }
    end

    def duplicate
      return unless @sale = find_and_check

      unless @sale.duplicatable?
        notify_error :sale_is_not_duplicatable
        redirect_to params[:redirect] || { action: :index }
        return
      end
      copy = @sale.duplicate(responsible: current_user.person)
      redirect_to params[:redirect] || { action: :show, id: copy.id }
    end

    def cancel
      return unless @sale = find_and_check

      url = { controller: :sale_credits, action: :new, credited_sale_id: @sale.id }
      url[:redirect] = params[:redirect] if params[:redirect]
      redirect_to url
    end

    def confirm
      return unless @sale = find_and_check

      if FinancialYearExchange.opened.at(@sale.invoiced_at).any?
        notify_error :financial_year_exchange_on_this_period
      else
        @sale.confirm
      end
      redirect_to action: :show, id: @sale.id
    end

    def contacts
      if request.xhr?
        address_id = nil
        client = if params[:selected] && address = EntityAddress.find_by(id: params[:selected])
                   address.entity
                 else
                   Entity.find_by(id: params[:client_id])
                 end
        if client
          session[:current_entity_id] = client.id
          address_id = (address ? address.id : client.default_mail_address.id)
        end
        @sale = Sale.find_by(id: params[:sale_id]) || Sale.new(address_id: address_id, delivery_address_id: address_id, invoice_address_id: address_id)
        render partial: 'addresses_form', locals: { client: client, object: @sale }
      else
        redirect_to action: :index
      end
    end

    def abort
      return unless @sale = find_and_check

      @sale.abort
      redirect_to action: :show, id: @sale.id
    end

    def correct
      return unless @sale = find_and_check

      @sale.correct
      redirect_to action: :show, id: @sale.id
    end

    def invoice
      return unless @sale = find_and_check

      if FinancialYearExchange.opened.at(@sale.invoiced_at).any?
        notify_error :financial_year_exchange_on_this_period
      elsif @sale.client.client_account.present?
        ApplicationRecord.transaction do
          raise ActiveRecord::Rollback unless @sale.invoice
        end
      else
        notify_error :error_client_account_empty
      end
      redirect_to action: :show, id: @sale.id
    end

    def propose
      return unless @sale = find_and_check

      @sale.propose
      redirect_to action: :show, id: @sale.id
    end

    def propose_and_invoice
      return unless @sale = find_and_check

      ApplicationRecord.transaction do
        raise ActiveRecord::Rollback unless @sale.propose
        raise ActiveRecord::Rollback unless @sale.confirm
        # raise ActiveRecord::Rollback unless @sale.deliver
        raise ActiveRecord::Rollback unless @sale.invoice
      end
      redirect_to action: :show, id: @sale.id
    end

    def refuse
      return unless @sale = find_and_check

      @sale.refuse
      redirect_to action: :show, id: @sale.id
    end

    def default_conditioning_unit
      product = ProductNatureVariant.find_by_id(params[:id].to_i)
      unit_id = product&.default_unit_id
      render json: {
        unit_id: unit_id.to_s,
        unit_name: Unit.find_by_id(unit_id)&.name&.to_s
      }
    end

    def conditioning_ratio
      conditioning = Conditioning.find_by_id(params[:id].to_i)
      coefficient = conditioning&.coefficient
      render json: { coeff: coefficient }
    end

    def conditioning_ratio_presence
      render json: Sale.find_by_id(params[:id])&.ratio_conditioning?
    end

    private

      def generate_n_send_pdf_for(sale, template)
        klass = printer_class(template.nature)
        if klass.nil?
          notify_error(:document_template_not_handled, nature: template.nature)

          return false
        end

        g = Ekylibre::DocumentManagement::DocumentGenerator.build
        printer = klass.new(template: template, sale: sale)
        pdf_data = g.generate_pdf(template: template, printer: printer)

        archiver = Ekylibre::DocumentManagement::DocumentArchiver.build
        archiver.archive_document(
          pdf_content: pdf_data,
          template: template,
          key: printer.key,
          name: printer.document_name
        )

        send_data pdf_data, filename: "#{printer.document_name}.pdf", type: 'application/pdf', disposition: 'inline'

        true
      end

      def printer_class(nature)
        case nature
        when 'sales_invoice'  then Printers::Sale::SalesInvoicePrinter
        when 'sales_invoice_shipment'  then Printers::Sale::SalesInvoiceShipmentPrinter
        when 'sales_order'    then Printers::Sale::SalesOrderPrinter
        when 'sales_estimate' then Printers::Sale::SalesEstimatePrinter
        else nil
        end
      end

      def create_response
        respond_with(@sale, methods: %i[taxes_amount affair_closed client_number sales_conditions sales_mentions],
                            include: { address: { methods: [:mail_coordinate] },
                                       nature: { include: { payment_mode: { include: :cash } } },
                                       supplier: { methods: [:picture_path], include: { default_mail_address: { methods: [:mail_coordinate] }, websites: {}, emails: {}, mobiles: {} } },
                                       responsible: {},
                                       credits: {},
                                       parcels: { methods: %i[human_delivery_mode human_delivery_nature items_quantity], include: {
                                         address: {},
                                         sender: {},
                                         recipient: {}
                                       } },
                                       affair: { methods: [:balance], include: [incoming_payments: { include: :mode }] },
                                       invoice_address: { methods: [:mail_coordinate] },
                                       items: { methods: %i[taxes_amount tax_name tax_short_label], include: [:variant, :shipment_item, :shipment, shipment_items: { include: %i[product parcel] }] } })
      end
  end
end
