# Themes (app/themes/<theme>/stylesheets, linked in app/assets/stylesheets/themes)
# are built by Dart Sass into app/assets/builds/themes/<theme>/all.css
Rails.application.config.dartsass.builds = Ekylibre::Application.instance.themes.to_h do |theme|
  ["themes/#{theme.name}/all.scss", "themes/#{theme.name}/all.css"]
end

gem_stylesheets = {
  'bootstrap-sass' => 'assets/stylesheets',
  'font-awesome-sass' => 'assets/stylesheets',
  'agric' => 'app/assets/stylesheets'
}.map { |name, path| File.join(Gem.loaded_specs[name].full_gem_path, path) }

load_paths = [
  Rails.root.join('app', 'assets', 'stylesheets'),
  Rails.root.join('vendor', 'stylesheets'),
  Rails.root.join('vendor', 'assets', 'stylesheets'),
  # Theme addons of the plugins (see Ekylibre::Plugin.generate_themes_stylesheets)
  Rails.root.join('tmp', 'plugins', 'theme-addons'),
  *gem_stylesheets
]

Rails.application.config.dartsass.build_options |= [
  *load_paths.map { |path| "--load-path=#{path}" },
  # Bootstrap 3 and Font Awesome 5 use deprecated Sass features
  '--quiet-deps', '--silence-deprecation=import', '--silence-deprecation=global-builtin',
  '--silence-deprecation=color-functions', '--silence-deprecation=slash-div', '--silence-deprecation=mixed-decls',
  '--silence-deprecation=if-function', '--silence-deprecation=function-units'
]
