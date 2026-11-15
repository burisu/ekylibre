visualization.Band = class Band {

  constructor(layer, data, options) {
    this.layer = layer;
    this.data = data;
    if (options == null) { options = {}; }
    this.items = [];
    const property = this.layer.reference;
    console.log("Property: ", property);
    let previous = null;
    let minValue = null;
    let maxValue = null;
    for (var zone of Array.from(this.data)) {
      if (minValue == null) { minValue = zone[property]; }
      if (maxValue == null) { maxValue = zone[property]; }
      if (minValue > zone[property]) { minValue = zone[property]; }
      if (maxValue < zone[property]) { maxValue = zone[property]; }
      if (previous) {
        this.items.push({
          polygon: this.computeTrapez({x: previous.shape.coordinates[1], y: previous.shape.coordinates[0], w: previous.width}, {x: zone.shape.coordinates[1], y: zone.shape.coordinates[0], w: zone.width}),
          value: zone[property],
          style: {
            stroke: false,
            fillOpacity: 1
          }
        });
      }
      previous = zone;
    }
    if (this.valid()) {
      const start = new visualization.Color(options.startColor);
      const stop  = new visualization.Color(options.stopColor);
      console.log(maxValue, minValue);
      for (var item of Array.from(this.items)) {
        var level = (item.value - minValue) / (maxValue - minValue);
        item.style.fillColor = visualization.Color.toString({
          red:   start.red   + (Math.round(stop.red   - start.red)   * level),
          green: start.green + (Math.round(stop.green - start.green) * level),
          blue:  start.blue  + (Math.round(stop.blue  - start.blue)  * level)
        });
      }
      console.log("Bands computed");
    } else {
      console.warn("Invalid bands");
    }
  }

  // Build layer as wanted
  buildLayerGroup(widget, globalStyle) {
    if (globalStyle == null) { globalStyle = {}; }
    const group = [];
    for (var item of Array.from(this.items)) {
      var edge = new L.polygon(item.polygon, item.style);
      group.push(edge);
    }
    return group;
  }

  // Build HTML legend for given bands computed layer
  buildLegend() {
    let html  = `<div class='leaflet-legend-item' id='legend-${this.layer.name}'>`;
    html += `<h3>${this.layer.label}</h3>`;
    // html += "<div class='leaflet-legend-body leaflet-categories-scale'>"
    // html += "<span class='leaflet-categories-items'>"
    // html += "<span class='leaflet-categories-item'>"
    // html += "<i class='leaflet-categories-sample' style='background-color: #{@items[0].fillColor};'></i>"
    // html += " #{@layer.label}"
    // html += "</span>"
    // html += "</span>"
    // html += "</div>"
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

  // Check if bands are valid
  valid() {
    return this.items.length > 0;
  }

  // http://stackoverflow.com/questions/7854043/drawing-rectangle-between-two-points-with-arbitrary-width
  computeTrapez(a, b) {
    // Calculate a vector between start and end points
    const v = {
      x: b.x - a.x,
      y: b.y - a.y
    };

    // Then calculate a perpendicular to it (just swap X and Y coordinates)
    const p = {
      x:  v.y, // Use separate variable otherwise you overwrite X coordinate here
      y: -v.x // Flip the sign of either the X or Y (edit by adam.wulf)
    };

    // Normalize that perpendicular
    const l = Math.sqrt((p.x * p.x) + (p.y * p.y)); // That's length of perpendicular
    const n = {
      x: p.x / l,
      y: p.y / l // Now N is normalized perpendicular
    };

    // Calculate 4 points that form a rectangle by adding normalized perpendicular and multiplying it by half of the desired width
    const ar = ((a.w / 2) * 9) / 1000000;
    const br = ((b.w / 2) * 9) / 1000000;
    const r1 = new L.LatLng(a.x + (n.x * ar), a.y + (n.y * ar));
    const r2 = new L.LatLng(a.x - (n.x * ar), a.y - (n.y * ar));
    const r3 = new L.LatLng(b.x + (n.x * br), b.y + (n.y * br));
    const r4 = new L.LatLng(b.x - (n.x * br), b.y - (n.y * br));
    return [r1, r2, r4, r3];
  }
};


visualization.registerLayerType("band", visualization.Band);
