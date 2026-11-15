# frozen_string_literal: true

require 'active_storage/service/disk_service'

module ActiveStorage
  # Disk service storing each tenant's files in its own directory: blob keys
  # are "<tenant>/<token>" (see config/initializers/active_storage.rb), files
  # are stored in <root>/<tenant>/<to>/<ke>/<token>. A tenant can then be
  # backed up or purged at once.
  class Service::TenantDiskService < Service::DiskService
    def path_for(key)
      tenant, token = key.to_s.split('/', 2)
      return super if token.nil?

      File.join(root, tenant, folder_for(token), token)
    end
  end
end
