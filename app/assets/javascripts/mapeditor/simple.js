mapeditor.Simple = class Simple {

  constructor(layer, data, options) {
    this.layer = layer;
    this.data = data;
    if (options == null) { options = {}; }
    this.options = options;
  }

  buildLayerGroup(widget, globalStyle) {
    if (globalStyle == null) { globalStyle = {}; }
    if (this.data === 'no_data') {
      return L.featureGroup();
    } else {
      return L.geoJson(this.data, {
        onEachFeature: (feature, layer) => {
          if (!feature.properties) { feature.properties = {}; }
          feature.properties['internal_id'] = new Date().getTime();
          if (feature.properties.name) {
            const label = new L.GhostLabel({className: 'leaflet-ghost-label', toBack: false}).setContent(feature.properties.name).toCentroidOfBounds(layer.getLatLngs());
            widget.ghostLabelCluster.bind(label, layer);
          }
          feature.properties['popupAttributes'] = globalStyle.popup || [];
          if (this.layer.popup) { return widget.popupizeSerie(feature, layer); }
        },

        style: feature => {
          if (feature.properties != null) { return $.extend({}, true, globalStyle, feature.properties); }
        }
      });
    }
  }

  buildLegend() {
    let html  = `<div class='leaflet-legend-item' id='legend-${this.layer.name}'>`;
    // html += "<h3>#{@layer.label}</h3>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>";
    html += "<span class='leaflet-categories-items'>";
    html += "<span class='leaflet-categories-item'>";
    html += `<i class='leaflet-categories-sample' style='background-color: ${this.layer.fillColor || this.options.parent.options.show.layerDefaults[this.layer.type].fillColor };'></i>`;
    html += ` <span class='leaflet-categories-item_label'>${this.layer.label}</span>`;
    html += "</span>";
    html += "</span>";
    html += "</div>";
    html += "</div>";
    return html;
  }

  // Check if categories are valid
  valid() {
    return true;
  }
};

mapeditor.registerLayerType("simple", mapeditor.Simple);
