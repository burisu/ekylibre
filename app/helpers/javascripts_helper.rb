# frozen_string_literal: true

# JavaScript of the layouts: import map modules (app/javascript, without
# build step) then the legacy jQuery scripts as deferred classic scripts.
# Deferred classic scripts and module scripts run in document order, so the
# legacy scripts find the globals set by the legacy_globals module.
module JavascriptsHelper
  LEGACY_JAVASCRIPTS = YAML.safe_load_file(Rails.root.join('config', 'legacy_javascripts.yml')).freeze

  # Images used by the JavaScript code (digested paths)
  JAVASCRIPT_ASSETS = %w[
    leaflet/marker-icon.png leaflet/marker-icon-2x.png leaflet/marker-shadow.png
    map/pause-icon.png map/pause-icon-2x.png
    map/marker/sensor.png map/marker/sensor-2x.png map/marker/shadow.png
  ].freeze

  def javascript_tags
    safe_join([
      javascript_asset_paths_tag,
      javascript_importmap_tags('application'),
      javascript_import_module_tag('legacy_globals'),
      javascript_include_tag(*LEGACY_JAVASCRIPTS, *Ekylibre::Plugin.javascripts, defer: true)
    ], "\n")
  end

  def javascript_asset_paths_tag
    paths = JAVASCRIPT_ASSETS.index_with { |path| asset_path(path) }
    javascript_tag("window.EkylibreAssets = #{paths.to_json};")
  end
end
