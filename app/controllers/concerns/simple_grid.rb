# frozen_string_literal: true

# Grid data for SimpleGridHelper#grid (replaces wice_grid's initialize_grid)
module SimpleGrid
  extend ActiveSupport::Concern

  class Grid
    def initialize(relation, decorate: false)
      @relation = relation
      @decorate = decorate
    end

    def resultset
      @resultset ||= @decorate ? @relation.decorate : @relation.to_a
    end
  end

  private

    def initialize_grid(relation, decorate: false, **_options)
      Grid.new(relation, decorate: decorate)
    end
end
