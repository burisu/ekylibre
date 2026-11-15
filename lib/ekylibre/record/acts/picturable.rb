module Ekylibre
  module Record
    module Acts
      # Picture attached with Active Storage, with thumb (64px), identity
      # (180px) and contact (720px) JPEG variants
      module Picturable
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def has_picture
            has_one_attached :picture do |attachable|
              attachable.variant :thumb, resize_and_pad: [64, 64, { background: 'white' }], format: :jpg
              attachable.variant :identity, resize_to_fill: [180, 180], format: :jpg
              attachable.variant :contact, resize_to_fill: [720, 720], format: :jpg
            end
            validates :picture, attachment_content_type: { with: /\Aimage/ }
            include PictureMethods
          end
        end

        module PictureMethods
          def has_picture?
            picture.attached?
          end

          # Local path of the picture or of one of its variants (thumb, identity, contact)
          def picture_path(style = nil)
            return nil unless picture.attached?
            return picture.blob.local_path if style.blank? || style.to_sym == :original

            picture.variant(style.to_sym).processed.image.blob.local_path
          end
        end
      end
    end
  end
end
