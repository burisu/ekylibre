# frozen_string_literal: true

require 'geo'

# Invalid geometries are repaired with PostGIS when possible
Geo.invalid_geometry_handler = lambda do |ewkt, _error|
  ShapeCorrector.build.try_fix_ewkt(ewkt).or_nil
end
