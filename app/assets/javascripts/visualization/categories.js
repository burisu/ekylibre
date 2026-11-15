visualization.Categories = class Categories {

  constructor(layer, data, options) {
    this.layer = layer;
    this.data = data;
    if (options == null) { options = {}; }
    this.items = [];
    const property = this.layer.reference;
    for (var zone of Array.from(this.data)) {
      if (!this.itemFor(zone[property])) {
        this.items.push({
          name: zone[property],
          color: zone['shapeColor']});
      }
    }

    if (this.valid()) {
      this.items = this.items.sort((a, b) => a.name > b.name);
      this.colors = options.colors != null ? options.colors : [];
      if (this.items.length > this.colors.length) {
        for (let x = this.colors.length, end = this.items.length, asc = this.colors.length <= end; asc ? x <= end : x >= end; asc ? x++ : x--) {
          this.colors.push(options.parent.options.colors[x] != null ? options.parent.options.colors[x] : "#000000");
        }
      }
      for (let index = 0; index < this.items.length; index++) {
        var item = this.items[index];
        if (item.color != null) {
          item.fillColor = item.color;
        } else {
          item.fillColor = this.colors[index];
        }
      }

      console.log("Categories computed");
    } else {
      console.warn("Invalid categories");
    }
  }

  // Build layer as wanted
  buildLayerGroup(widget, globalStyle) {
    if (globalStyle == null) { globalStyle = {}; }
    const group = [];
    for (var zone of Array.from(this.data)) {
      var zoneStyle =
        {fillColor: this.itemFor(zone[this.layer.reference]).fillColor};
      var zoneLayer = new L.GeoJSON(zone.shape, $.extend(true, {}, globalStyle, zoneStyle));
      widget._bindPopup(zoneLayer, zone);
      if (!this.layer.withoutGhostLabel) {
        var label = new L.GhostLabel({className: 'leaflet-ghost-label', toBack: false}).setContent(zone.name).toCentroidOfBounds(zoneLayer.getLayers()[0].getLatLngs());
        widget.ghostLabelCluster.bind(label, zoneLayer.getLayers()[0]);
      }
      group.push(zoneLayer);
    }
    return group;
  }

  // Build HTML legend for given categories computed layer
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
    return this.items.length > 0;
  }
};

visualization.registerLayerType("categories", visualization.Categories);
