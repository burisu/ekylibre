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
# == Table: intervention_models
#
#  category_name       :jsonb
#  id                  :string           not null, primary key
#  name                :jsonb
#  number              :string
#  procedure_reference :string           not null
#  working_flow        :decimal(19, 4)
#  working_flow_unit   :string
#
class InterventionModel < LexiconRecord
  include Lexiconable
  has_many :items, class_name: 'InterventionModelItem', foreign_key: :intervention_model_id, dependent: :restrict_with_exception
  has_many :technical_workflow_procedure, class_name: 'TechnicalWorkflowProcedure', foreign_key: :procedure_reference, dependent: :restrict_with_exception

  def procedure
    Procedo.find(procedure_reference)
  end
end
