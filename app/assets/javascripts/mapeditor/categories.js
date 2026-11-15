mapeditor.Categories = class Categories {

  constructor(layer, data, options) {
    this.layer = layer;
    this.data = data;
    if (options == null) { options = {}; }
    this.options = options;
    this.items = [];
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
          if (this.layer.popup) { widget.popupizeSerie(feature, layer); }

          if (!this.itemFor(feature.properties[this.layer.reference])) { return this.items.push({name: feature.properties[this.layer.reference], fillColor: feature.properties.color}); }
        },

        style: feature => {
          return $.extend({}, true, globalStyle, feature.properties);
        }
      });
    }
  }

  buildLegend() {
    let html  = `<div class='leaflet-legend-item' id='legend-${this.layer.name}'>`;
    html += `<h3>${this.layer.label}</h3>`;
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>";
    html += "<span class='leaflet-categories-items'>";
    for (var name in this.items) {
      var item = this.items[name];
      html += "<span class='leaflet-categories-item'>";
      html += `<i class='leaflet-categories-sample' style='background-color: ${item.fillColor};'></i>`;
      html += ` <span class='leaflet-categories-item_label'>${item.name}</span>`;
      html += "</span>";
    }
    html += "</span>";
    html += "</div>";
    html += "</div>";
    return html;
  }

// Returns the item matching the given name
  itemFor(name) {
    let back = null;
    this.items.forEach(function(item, index, array) {
      if (item.name === name) { return back = item; }
    });
    return back;
  }

// Check if categories are valid
  valid() {
    return true;
  }
};

mapeditor.registerLayerType("categories", mapeditor.Categories);
