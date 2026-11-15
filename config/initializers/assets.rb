# Be sure to restart your server when you modify this file.
Rails.application.configure do
  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Fonts of the Bootstrap 3 and Font Awesome themes (see config/initializers/dartsass.rb)
  %w[bootstrap-sass font-awesome-sass].each do |name|
    config.assets.paths << File.join(Gem.loaded_specs[name].full_gem_path, 'assets', 'fonts')
  end
  # Agric icon font (app/themes/tekyla/stylesheets/fonts.scss)
  config.assets.paths << File.join(Gem.loaded_specs['agric'].full_gem_path, 'app', 'assets', 'fonts')
end
