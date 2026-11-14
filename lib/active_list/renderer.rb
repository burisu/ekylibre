# frozen_string_literal: true

module ActiveList
  # Renders a list as HTML in a view context. Markup is kept identical to
  # the former active_list gem so existing JS/CSS keep working.
  class Renderer
    DATATYPE_ABBREVIATION = {
      binary: :bin, boolean: :bln, date: :dat, datetime: :dtt, decimal: :dec,
      measure: :dec, float: :flt, integer: :int, string: :str, text: :txt,
      time: :tim, timestamp: :dtt
    }.freeze
    PAGE_SIZES = [5, 10, 20, 50, 100, 200].freeze
    LEVELS = %w[go caution stop].freeze

    attr_reader :table, :view, :state, :query

    delegate :content_tag, :tag, :link_to, :mail_to, :image_tag, :url_for, :safe_join, to: :view

    def h(value)
      ERB::Util.html_escape(value)
    end

    def initialize(table, view, options = {})
      @table = table
      @view = view
      @state = State.new(table, view, options)
      @query = Query.new(table, view, @state)
    end

    def render(&block)
      records = query.records
      view.instance_variable_set("@#{table.name}", records)
      tbody = tbody_html(records)
      return tbody if state[:only] == 'table-body'

      content = +''
      extras = extras_html
      if extras.any?
        content_for = state.options[:content_for] || {}
        extra_html = +''
        extras.each do |name, html|
          next if name == :footer_pagination

          if content_for[name]
            view.content_for(content_for[name], html.html_safe)
          else
            extra_html << html
          end
        end
        content << content_tag(:div, extra_html.html_safe, class: 'list-control') if extra_html.present?
      end
      content << '<div class="list-data"><table class="list"'
      content << %( data-list-current-page="#{query.page}" data-list-page-size="#{query.limit}") if table.paginate?
      content << %( data-list-sort-by="#{h(state[:sort])}" data-list-sort-dir="#{h(state[:dir])}">)
      content << header_html
      if block
        columns = table.columns.collect { |c| { name: c.name, id: c.id } }
        content << '<tfoot>' << view.capture(columns, &block).to_s << '</tfoot>'
      end
      content << tbody
      content << '</table></div>'
      if table.options[:footer_pagination] && extras[:footer_pagination]
        content << content_tag(:div, extras[:footer_pagination].html_safe, class: 'list-control')
      end

      source = url_for(state.options.except(:content_for, :only).merge(action: table.action_name))
      redirect = view.params[:redirect] || (view.respond_to?(:request) ? view.request&.fullpath : nil)
      %(<div id="#{table.uid}" data-list-source="#{h(source)}" data-list-redirect="#{h(redirect)}" class="active-list">#{content}</div>).html_safe
    end

    private

      def tbody_html(records)
        html = +%(<tbody data-total="#{query.count}")
        html << %( data-per-page="#{query.limit}" data-pages-count="#{query.last_page}") if table.paginate?
        html << '>'
        if query.count.positive?
          focus_id = view.params["#{table.name}-id"].to_i
          records.each do |record|
            attrs = { id: "r#{record.id}" }
            Array(state[:data]).each do |attr|
              attr = attr.to_s
              next unless record.has_attribute?(attr) || record.class.method_defined?(attr)

              attrs["data-#{attr.tr('_', '-')}"] = record.public_send(attr)
            end
            classes = table.options[:line_class] ? Evaluation.record_value(view, table.options[:line_class], record).to_s.dup : +''
            classes << ' focus' if focus_id == record.id
            attrs[:class] = classes.strip if classes.present?
            html << content_tag(:tr, row_cells(record), attrs)
          end
          html << computation_row if table.columns.any?(&:computable?)
        else
          html << %(<tr class="empty"><td colspan="#{table.columns.size + 1}">#{h(::I18n.translate('list.no_records'))}</td></tr>)
        end
        html << '</tbody>'
        html.html_safe
      end

      def computation_row
        cells = +''
        cells << '<td></td>' if table.selectable?
        table.columns.each do |column|
          cells << '<td'
          value = ''
          if column.computable?
            cells << %( data-list-result-for="#{column.short_id}")
            value = "<div><span><strong>#{h(I18n.translate("list.results.#{column.computation_method}"))}:</strong></span><span id='list-computation-result'></span></div>"
          end
          cells << %( class="#{column.short_id}#{' hidden' if state.hidden?(column)}") if column.data?
          cells << '>' << value << '</td>'
        end
        content_tag(:tr, cells.html_safe, id: :'computation-results')
      end

      def row_cells(record)
        cells = []
        if table.selectable?
          cells << content_tag(:td, tag(:input, type: 'checkbox', value: record.id, data: { list_selector: record.id }), class: 'list-selector')
        end
        table.columns.each do |column|
          next if column.is_a?(Definition::ActionColumn) && !column.use_single?

          value, title = cell_value(column, record)
          attrs = { class: column_classes(column), data: { 'list-column-header' => column.short_id } }
          attrs[:title] = title unless title.nil?
          attrs[:data]['list-cell-value'] = column.datum_value(record).to_f.to_s if column.computable?
          cells << content_tag(:td, value, attrs)
        end
        safe_join(cells)
      end

      # Returns [html, title]
      def cell_value(column, record)
        case column
        when Definition::EmptyColumn
          [nil, nil]
        when Definition::StatusColumn
          value = column.datum(record).to_s
          lights = safe_join(LEVELS.map { |light| content_tag(:span, '', class: light) }, ' ')
          [content_tag(:span, lights, class: 'lights lights-' + (LEVELS.include?(value) ? value : 'undefined'), data: { toggle: :tooltip, placement: :top }, title: column.tooltip_title(record)), nil]
        when Definition::DataColumn
          data_cell_value(column, record)
        when Definition::CheckBoxColumn
          form_name = column.form_name_for(view, record)
          checked = Evaluation.record_value(view, column.options[:value] || column.name, record)
          html = if column.form_value
                   view.check_box_tag(form_name, Evaluation.record_value(view, column.form_value, record), checked)
                 else
                   view.hidden_field_tag(form_name, 0, id: nil) + view.check_box_tag(form_name, 1, checked)
                 end
          [html, nil]
        when Definition::TextFieldColumn
          value = Evaluation.record_value(view, column.options[:value] || column.name, record)
          opts = column.options[:size] ? { size: column.options[:size] } : {}
          [view.text_field_tag(column.form_name_for(view, record), value, opts), nil]
        when Definition::IconColumn
          [column.visible_for?(view, record) ? content_tag(:i) : nil, nil]
        when Definition::ActionColumn
          [column.operation(view, record), nil]
        else
          ['&#160;&#8709;&#160;'.html_safe, nil]
        end
      end

      def data_cell_value(column, record)
        return [nil, nil] if column.is_a?(Definition::AssociationColumn) && record.nil?

        raw = column.datum(record)
        value = raw
        title = ''
        if column.datatype == :boolean
          title = raw
          value = content_tag(:div, '', class: 'checkbox-' + (raw ? 'true' : 'false'))
        elsif %i[date datetime timestamp measure].include?(column.datatype)
          value = raw.nil? ? '' : raw.l
        elsif column.datatype == :item
          value = raw.nil? ? '' : raw.human_name
        end

        currency = column.options[:currency]
        if currency && !currency.is_a?(FalseClass)
          currency_value = column.currency_for(view, record)
          default = column.options[:default]
          value = raw.nil? || raw.zero? ? (default.present? ? default : '') : raw.l(currency: currency_value)
        elsif column.datatype == :decimal
          value = raw.nil? ? '' : raw.l
        elsif column.enumerize?
          value = raw.nil? ? '' : raw.text
        end

        label_method = column.respond_to?(:label_method) ? column.label_method : nil
        if column.options[:url]
          title = value
          value = value.blank? ? '' : link_to(value.to_s, column_url(column, record))
        elsif column.options[:mode] || label_method == :email
          title = value
          value = value.blank? ? '' : mail_to(value)
        elsif label_method == :website
          title = value
          value = value.blank? ? '' : link_to(value, value)
        elsif label_method == :color
          title = value
          value = content_tag(:div, raw, style: "background: ##{raw}")
        elsif label_method.to_s =~ /(^|_)currency$/ && column.datatype == :string
          value = Onoma::Currency[value] ? Onoma::Currency[value].human_name : value
        elsif label_method.to_s =~ /(^|_)language$/ && column.datatype == :string
          value = Onoma::Language[value] ? Onoma::Language[value].human_name : value
        elsif label_method.to_s =~ /(^|_)country$/ && column.datatype == :string
          value = Onoma::Country[value] ? (image_tag("countries/#{value}.png") + ' ' + Onoma::Country[value].human_name) : value
        else
          value = h(value.to_s)
          title = nil
        end
        title = value if title == ''
        [value, title.is_a?(String) || title.nil? ? title : title.to_s]
      end

      def column_url(column, record)
        url = column.options[:url].is_a?(Hash) ? column.options[:url].dup : {}
        namespace = url.delete(:namespace)
        target = column.record_of(record)
        url[:id] ||= target&.id
        url[:action] ||= :show
        dynamic_controller = url[:controller].is_a?(Proc) || (url[:controller].nil? && column.is_a?(Definition::AttributeColumn))
        url[:controller] ||= column.default_url_controller(record)
        url = Evaluation.deep(view, url, record)
        url[:controller] = "/#{namespace}/#{url[:controller]}" if namespace && dynamic_controller
        url
      end

      def header_html
        html = +'<thead><tr>'
        if table.selectable?
          html << '<th class="list-selector"><input type="checkbox" data-list-selector="all" /></th>'
          disclaimer = %(<tr class="selected-count" style="display: none;"><th colspan="1000">#{h('list.selected'.t)}</th></tr>)
        end
        table.columns.each do |column|
          next if column.is_a?(Definition::ActionColumn) && !column.use_single?

          html << %(<th data-list-column="#{column.options[:icon_name] || column.sort_id}")
          html << %( data-list-column-cells="#{column.short_id}")
          if column.sortable?
            next_dir = state[:sort] != column.sort_id.to_s ? 'asc' : (state[:dir] == 'asc' ? 'desc' : 'asc')
            html << %( data-list-column-sort="#{next_dir}")
          end
          html << %( data-list-column-computation="#{column.computation_method}") if column.computable?
          if table.selectable? && column.data? && (column.options[:currency] || column.computable?)
            unit, precision = column_unit(column)
            html << %( data-list-column-unit-symbol="#{h(unit)}" data-list-column-unit-precision="#{h(precision)}")
          end
          html << %( class="#{column_classes(column, true)}">)
          html << h(column.header(view)) << '<i></i></th>'
        end
        html << '</tr>' << (disclaimer || '') << '</thead>'
        html
      end

      def column_unit(column)
        record = view.instance_variable_get("@#{table.name}")&.first
        return ['', ''] unless record

        if column.options[:currency]
          currency = Onoma::Currency.find(column.currency_for(view, record) || 'EUR')
          [currency.symbol.to_s, currency.precision.to_s]
        else
          [column.datum_value(record).symbol, '2']
        end
      end

      def menu_html
        menu = +%(<span class="list-settings" data-list-ref="#{table.uid}">)
        menu << %(<a class="settings-start"><i></i>#{h('list.menu'.t)}</a><ul>)
        if table.paginate?
          sizes = PAGE_SIZES.dup
          sizes << table.options[:per_page].to_i if table.options[:per_page].to_i.positive?
          menu << %(<li class="parent"><a class="pages"><i></i>#{h('list.items_per_page'.t)}</a><ul>)
          sizes.uniq.sort.each do |n|
            menu << %(<li data-list-change-page-size="#{n}"#{' class="check"' if state[:per_page] == n}><a><i></i>#{h('list.x_per_page'.t(count: n))}</a></li>)
          end
          menu << '</ul></li>'
        end
        menu << %(<li class="parent"><a class="columns"><i></i>#{h('list.columns'.t)}</a><ul>)
        table.data_columns.each do |column|
          menu << %(<li data-list-toggle-column="#{column.name}" class="#{state.hidden?(column) ? 'unchecked' : 'checked'}"><a><i></i>#{h(column.header(view))}</a></li>)
        end
        menu << '</ul></li><li class="separator"></li>'
        request_params = view.params.respond_to?(:to_unsafe_h) ? view.params.to_unsafe_h : view.params.to_h
        ActiveList.export_formats.each do |format|
          label = 'list.export_as'.t(exported: format.t(scope: 'list.export.formats'))
          url = request_params.merge(action: table.action_name, sort: state[:sort], dir: state[:dir], format: format.to_s)
          menu << %(<li class="export export-#{format}">#{link_to(content_tag(:i) + h(label), url)}</li>)
        end
        menu << '</ul></span>'
      end

      def extras_html
        codes = {}
        if table.global_action_columns.any?
          actions = +%(<span class="list-actions" data-list-ref="#{table.uid}">)
          table.global_action_columns.each do |column|
            opts = { class: "btn btn-#{column.name}", data: { list_actioner: column.use_none? ? :none : :many } }
            opts[:style] = 'display: none' unless column.use_none?
            opts[:method] = column.options[:method].to_s if column.options[:method]
            opts[:data][:confirm] = column.options[:confirm].to_s.t(scope: 'labels') if column.options[:confirm]
            actions << link_to(content_tag(:i) + h(' ' + column.name.t(scope: 'rest.actions')), column.default_url(view), opts)
          end
          actions << '</span>'
          codes[:actions] = actions
        end
        codes[:settings] = menu_html
        if table.paginate?
          codes[:pagination] = pagination_html('list-pagination')
          codes[:footer_pagination] = pagination_html('list-footer-pagination') if table.options[:footer_pagination]
        end
        codes
      end

      def pagination_html(css_class)
        page = query.page
        last = query.last_page
        count = query.count
        x = query.offset + (count.positive? ? 1 : 0)
        y = last == page ? count : query.offset + query.limit
        html = +%(<span class="#{css_class}" data-list-ref="#{table.uid}">)
        html << %(<span class="status">#{h('list.pagination.x_to_y_of_total'.t(x: x, y: y, total: count))}</span>)
        html << '<span class="paginator">'
        html << %(<a href="#" data-list-move-to-page="#{page - 1}" class="btn previous-page"#{' disabled="true"' if page == 1}><i></i>#{h(::I18n.translate('list.pagination.previous'))}</a>)
        html << %(<a href="#" data-list-move-to-page="#{page + 1}" class="btn next-page"#{' disabled="true"' if page == last}><i></i>#{h(::I18n.translate('list.pagination.next'))}</a>)
        html << '</span></span>'
      end

      def column_classes(column, without_id = false)
        classes = []
        classes << column.options[:class].to_s.strip if column.options[:class].present?
        classes << column.short_id unless without_id
        case column
        when Definition::ActionColumn
          classes << :act
        when Definition::StatusColumn
          classes << :status
        when Definition::DataColumn
          classes << :col
          classes << DATATYPE_ABBREVIATION[column.datatype]
          classes << :url if column.options[:url].is_a?(Hash)
          label_method = column.respond_to?(:label_method) ? column.label_method : nil
          classes << label_method if label_method.is_a?(Symbol) && %i[code color].include?(label_method)
          if column.options[:mode] == :download
            classes << :dld
          elsif column.options[:mode] || label_method == :email
            classes << :eml
          elsif label_method == :website
            classes << :web
          end
        when Definition::TextFieldColumn
          classes << :tfd
        when Definition::CheckBoxColumn
          classes << :chk
        when Definition::IconColumn
          classes << :act
          classes << "icon-#{column.name}"
        else
          classes << :unk
        end
        classes << :sor if column.sortable? && state[:sort] == column.sort_id.to_s
        if column.data?
          classes << :hidden if state.hidden?(column)
        elsif column.condition
          classes << :hidden if h(Evaluation.value(view, column.condition)).to_s == 'false'
        end
        classes.compact.join(' ').strip
      end
  end
end
