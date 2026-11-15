module Ekylibre
  class Extension
    class << self
      # Insert the css file to the plugins.scss tmp file.
      # The plugins.scss file is inserted to all.scss.
      def insert_css_file(extension_name)
        Ekylibre.themes.each do |theme|
          stylesheet = "// This files contains #{theme} theme addons from plugins\n\n"
          stylesheet << "@import \"#{extension_name}\";\n"

          file_path = "themes/#{theme}/plugins.scss"
          write_asset_tmp_file('theme-addons', file_path, stylesheet)
        end
      end

      # Adds the js file to the scripts loaded after the application ones
      def insert_js_file(extension_name)
        path = extension_name.to_s
        path += '.js' unless path.end_with?('.js')
        Ekylibre::Plugin.javascripts << path unless Ekylibre::Plugin.javascripts.include?(path)
      end

      private

        def write_asset_tmp_file(folder, file_path, file_content)
          base_dir = Rails.root.join('tmp', 'plugins', folder)
          Rails.application.config.assets.paths << base_dir.to_s

          file = base_dir.join(file_path)

          FileUtils.mkdir_p file.dirname
          File.write(file, file_content)
        end
    end
  end
end
