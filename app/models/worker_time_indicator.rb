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
# == Materialized View: working_time_indicators
#  worker_id           :integer             not null
#  start_at            :datetime            not null
#  stop_at             :datetime            not null
#  duration            :interval
#
# Compile 3 sources of time in a view group by worker
# - working_time coming from WorkingTimeLog for one worker
# - working period coming from intervention for a worker as a doer with no participations
# - working period coming from intervention for a worker as a doer with participations (detailled times)
# each period (started_at / stopped_at) are lag by other if overlapps
# ex :
# period 1 => 01/01/2022 - 09H00 - 12H00
# period 2 => 01/01/2022 - 08H00 - 11H30
# period 3 => 01/01/2022 - 07H00 - 10H30
# => 01/01/2022 - 07H00 - 12H00

class WorkerTimeIndicator < ApplicationRecord
  include HasInterval

  belongs_to :worker

  has_interval :duration

  scope :between, lambda { |started_at, stopped_at|
    where(start_at: started_at..stopped_at)
  }

  scope :of_year, lambda { |year|
    where('EXTRACT(YEAR FROM start_at) = ?', year)
  }

  scope :of_workers, lambda { |workers|
    where(worker: workers)
  }

  class << self
    def refresh
      Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
    end
  end

  def readonly?
    true
  end

end
