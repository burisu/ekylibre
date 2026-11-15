# frozen_string_literal: true

# Minimal replacement of the wice_grid gem (MIT, Yuri Leikind) for the few
# simple grids of the application:
#   grid(@grid, html: {}) { |g| g.column(name:, html:) { |record| ... } }
# The markup is the one of wice_grid 4.1 (container, title row, footer with
# pagination and status, odd/even rows) so styles and scripts still apply.
module SimpleGridHelper
  # Collects grid columns
  class Builder
    Column = Struct.new(:name, :html, :block)

    attr_reader :columns

    def initialize
      @columns = []
    end

    def column(name: '', html: {}, **_options, &block)
      @columns << Column.new(name, html, block)
    end
  end

  SHOW_ALL_LABELS = { fra: 'Voir tous', eng: 'show all' }.freeze
  SHOW_ALL_TOOLTIPS = { fra: 'Voir tous les enregistrements', eng: 'Show all records' }.freeze
  BACK_TO_PAGINATION_LABELS = { fra: 'Retour à la pagination', eng: 'back to paginated mode' }.freeze

  def grid(grid, html: {}, &block)
    builder = Builder.new
    capture(builder, &block)
    columns = builder.columns
    table_options = html.merge(class: ['table-striped table-bordered table wice-grid', html[:class]].compact.join(' '))

    head = content_tag(:thead) do
      content_tag(:tr, class: 'wice-grid-title-row') do
        safe_join(columns.map { |c| content_tag(:th, c.name, c.html.merge(class: c.html[:class].to_s)) })
      end
    end
    foot = content_tag(:tfoot) do
      content_tag(:tr, content_tag(:td, simple_grid_pagination(grid), colspan: columns.size))
    end
    rows = grid.resultset.each_with_index.map do |record, index|
      content_tag(:tr, class: index.even? ? 'odd' : 'even') do
        safe_join(columns.map { |c| content_tag(:td, c.block.call(record), c.html) })
      end
    end

    content_tag(:div, class: 'wice-grid-container table-responsive', id: grid.name, data: { grid_name: grid.name }) do
      content_tag(:div, nil, id: "#{grid.name}_title") +
        content_tag(:table, head + foot + content_tag(:tbody, safe_join(rows)), table_options)
    end
  end

  private

    def simple_grid_pagination(grid)
      relation = grid.page_relation
      links = paginate(relation, theme: 'wice_grid', param_name: "#{grid.name}[page]", inner_window: 4, outer_window: 2)
      safe_join([links, ' '.html_safe, content_tag(:div, simple_grid_status(grid, relation), class: 'pagination_status')])
    end

    def simple_grid_status(grid, relation)
      count = relation.to_a.size
      total = grid.total_count
      locale = I18n.locale.to_sym
      status = if relation.total_pages < 2 && count.zero?
                 ERB::Util.html_escape('0').dup
               else
                 first = grid.all_record_mode? ? 1 : relation.offset_value + 1
                 last = grid.all_record_mode? || relation.last_page? ? total : relation.offset_value + relation.limit_value
                 text = ERB::Util.html_escape("#{first}-#{last} / #{total} ").dup
                 if total > count
                   text << link_to(SHOW_ALL_LABELS.fetch(locale, SHOW_ALL_LABELS[:eng]),
                                   url_for(request.query_parameters.merge(grid.name => { pp: total })),
                                   title: SHOW_ALL_TOOLTIPS.fetch(locale, SHOW_ALL_TOOLTIPS[:eng]), class: 'wg-show-all-link')
                 end
                 text
               end
      if grid.all_record_mode?
        status << link_to(BACK_TO_PAGINATION_LABELS.fetch(locale, BACK_TO_PAGINATION_LABELS[:eng]),
                          url_for(request.query_parameters.except(grid.name)), class: 'wg-back-to-pagination-link')
      end
      status.html_safe? ? status : ERB::Util.html_escape(status)
    end
end
