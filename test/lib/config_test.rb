require 'test_helper'

class ConfigTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'attachments are stored by tenant' do
    tenant = Ekylibre::Tenant.current
    assert_equal 'test', tenant
    blob = ActiveStorage::Blob.new(filename: 'test.txt', byte_size: 0, checksum: 'x')
    assert blob.key.start_with?("#{tenant}/"), "Blob key must be prefixed by the tenant: #{blob.key}"
  end
end
