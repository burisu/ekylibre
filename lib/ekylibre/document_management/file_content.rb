# frozen_string_literal: true

require 'open3'

module Ekylibre
  module DocumentManagement
    # Reads the pages count and the text of a document file: text layer of
    # PDFs (poppler pdftotext/pdfinfo), OCR of images and scanned PDFs
    # (tesseract). Other formats have no text.
    class FileContent
      OCR_LANGUAGES = 'fra+eng'

      attr_reader :path, :content_type

      def initialize(path, content_type: nil)
        @path = path.to_s
        @content_type = content_type.to_s
      end

      def pdf?
        content_type == 'application/pdf' || File.binread(path, 5) == '%PDF-'
      end

      def image?
        content_type.start_with?('image/')
      end

      def pages_count
        return 1 if image?
        return nil unless pdf?

        output = run('pdfinfo', path)
        output && output[/^Pages:\s+(\d+)/, 1]&.to_i
      end

      def text
        if pdf?
          text = run('pdftotext', '-layout', '-enc', 'UTF-8', path, '-')
          text.present? && text.strip.present? ? text : ocr_pdf
        elsif image?
          ocr(path)
        elsif content_type.start_with?('text/')
          File.read(path, encoding: 'UTF-8', invalid: :replace, undef: :replace)
        end
      end

      private

        def ocr_pdf
          Dir.mktmpdir do |dir|
            return nil unless run('pdftoppm', '-r', '150', '-png', path, File.join(dir, 'page'))

            Dir[File.join(dir, 'page*.png')].sort.map { |page| ocr(page) }.compact.join("\f")
          end
        end

        def ocr(image_path)
          run('tesseract', image_path, 'stdout', '-l', OCR_LANGUAGES)
        end

        def run(*command)
          output, status = Open3.capture2(*command, err: File::NULL)
          status.success? ? output.force_encoding('UTF-8').scrub : nil
        rescue Errno::ENOENT
          Rails.logger.warn("#{command.first} is not installed: cannot read #{path}")
          nil
        end
    end
  end
end
