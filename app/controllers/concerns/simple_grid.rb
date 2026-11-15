# frozen_string_literal: true

# Grid data for SimpleGridHelper#grid (replaces wice_grid's initialize_grid).
# Like wice_grid, records are paginated (20 per page, `grid[page]` param) and
# can all be shown at once (`grid[pp]` param).
module SimpleGrid
  extend ActiveSupport::Concern

  PER_PAGE = 20

  class Grid
    attr_reader :name

    def initialize(relation, params:, name: 'grid', decorate: false, per_page: PER_PAGE)
      @relation = relation
      @name = name
      @decorate = decorate
      grid_params = params[name]
      grid_params = grid_params.to_unsafe_h if grid_params.respond_to?(:to_unsafe_h)
      grid_params = {} unless grid_params.is_a?(Hash)
      @page = [grid_params['page'].to_i, 1].max
      @all_records = grid_params['pp'].present?
      @per_page = per_page
    end

    def all_record_mode?
      @all_records
    end

    # Records of the current page (Kaminari relation)
    def page_relation
      @page_relation ||= if all_record_mode?
                           @relation.page(1).per(total_count.positive? ? total_count : 1)
                         else
                           @relation.page(@page).per(@per_page)
                         end
    end

    def total_count
      @total_count ||= @relation.page(1).total_count
    end

    def resultset
      @resultset ||= @decorate ? page_relation.decorate : page_relation.to_a
    end
  end

  private

    def initialize_grid(relation, decorate: false, name: 'grid', per_page: PER_PAGE, **_options)
      Grid.new(relation, params: params, name: name, decorate: decorate, per_page: per_page)
    end
end
