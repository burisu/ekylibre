# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: operation_lines
#
#  area_unit_id    :integer          
#  company_id      :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer          
#  direction       :string(4)        default("in"), not null
#  id              :integer          not null, primary key
#  location_id     :integer          
#  lock_version    :integer          default(0), not null
#  operation_id    :integer          not null
#  product_id      :integer          
#  quantity        :decimal(, )      default(0.0), not null
#  tracking_id     :integer          
#  tracking_serial :string(255)      
#  unit_id         :integer          
#  unit_quantity   :decimal(, )      default(0.0), not null
#  updated_at      :datetime         not null
#  updater_id      :integer          
#

require 'test_helper'

class ShapeOperationLineTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
