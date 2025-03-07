# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: registered_soil_depths
#
# id character varying PRIMARY KEY NOT NULL,
# soil_depth_value numeric(19,4),
# soil_depth_unit character varying,
# shape postgis.geometry(MultiPolygon, 4326) NOT NULL
#
class RegisteredSoilDepth < LexiconRecord
  include Lexiconable
  include Ekylibre::Record::HasShape
  composed_of :soil_depth, class_name: 'Measure', mapping: [%w[soil_depth_value to_d], %w[soil_depth_unit unit]]

  has_geometry :shape
end
