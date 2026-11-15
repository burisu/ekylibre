require 'test_helper'

module Upgrade
  # Files and pictures are stored with Active Storage (formerly Paperclip)
  class PicturesTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::ProductNatureVariantsController

    setup do
      sign_in(create(:user))
      @variant = ProductNatureVariant.first
    end

    test 'picture is served in its original and variant styles' do
      @variant.picture.attach(io: File.open(fixture_file('logo.png')), filename: 'logo.png', content_type: 'image/png')
      assert @variant.picture.attached?
      assert @variant.picture.blob.key.start_with?("#{Ekylibre::Tenant.current}/"), 'Blob keys are prefixed by the tenant'

      get :picture, params: { id: @variant.id }
      assert_response :success
      assert_equal File.binread(fixture_file('logo.png')), response.body

      get :picture, params: { id: @variant.id, style: :thumb }
      assert_response :success
      assert_equal 'image/jpeg', Marcel::MimeType.for(StringIO.new(response.body))
    end

    test 'missing picture is not found' do
      @variant.picture.purge if @variant.picture.attached?
      get :picture, params: { id: @variant.id }
      assert_response :not_found
    end

    test 'picture must be an image' do
      @variant.picture.attach(io: StringIO.new('not an image'), filename: 'file.txt', content_type: 'text/plain')
      refute @variant.valid?
      assert @variant.errors[:picture].any?
    end
  end

  class DocumentsFilesTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::DocumentsController

    setup do
      sign_in(create(:user))
    end

    test 'uploaded document keeps its metadata, pages count and content' do
      document = Document.create!(name: 'Dummy', file: File.open(fixture_file('document_management', 'dummy_pdf.pdf')))
      assert_equal 'dummy_pdf.pdf', document.file_file_name
      assert_equal 'application/pdf', document.file_content_type
      assert_equal File.size(fixture_file('document_management', 'dummy_pdf.pdf')), document.file_file_size
      assert_equal 1, document.file_pages_count

      get :show, params: { id: document.id, format: :pdf }
      assert_response :success
      assert_equal File.binread(fixture_file('document_management', 'dummy_pdf.pdf')), response.body

      get :show, params: { id: document.id, format: :jpg }
      assert_response :success
      assert_equal 'image/jpeg', Marcel::MimeType.for(StringIO.new(response.body))
    end
  end

  class AttachmentsFilesTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::AttachmentsController

    setup do
      sign_in(create(:user))
    end

    test 'attachment gives the path of its document file' do
      attachment = Attachment.first
      get :show, params: { id: attachment.id }
      assert_response :success
      assert_includes JSON.parse(response.body).dig('document', 'file_path'), "/backend/documents/#{attachment.document_id}"
    end
  end

  class ImportsFilesTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::ImportsController

    setup do
      sign_in(create(:user))
    end

    test 'import archive is attached with its metadata' do
      file = fixture_file_upload(fixture_file('imports', 'isagri', 'isapaye', 'ecr_journal_entries.ecr'), 'text/plain')
      assert_difference 'Import.count' do
        post :create, params: { import: { nature: :isagri_isapaye_ecr_journal_entries, archive: file } }
      end
      import = Import.order(:id).last
      assert import.archive.attached?
      assert_equal 'ecr_journal_entries.ecr', import.archive_file_name
      assert File.exist?(import.archive_path)
    end
  end
end
