# frozen_string_literal: true

# Minimal replacement of the wice_grid gem for the few simple grids of the
# application: `grid(@grid, html: {}) { |g| g.column(name:, html:) { |record| ... } }`
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

  def grid(grid, html: {}, &block)
    builder = Builder.new
    capture(builder, &block)
    table_options = html.merge(class: ['wice-grid', 'table', 'table-bordered', 'table-striped', html[:class]].compact.join(' '))
    content_tag(:table, table_options) do
      head = content_tag(:thead) do
        content_tag(:tr, safe_join(builder.columns.map { |c| content_tag(:th, c.name, c.html) }))
      end
      rows = grid.resultset.map do |record|
        content_tag(:tr, safe_join(builder.columns.map { |c| content_tag(:td, c.block.call(record), c.html.except(:style)) }))
      end
      head + content_tag(:tbody, safe_join(rows))
    end
  end
end
