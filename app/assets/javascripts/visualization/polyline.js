// visualization.Polyline class
// displays Stringline
//
// @data is an array of one hash containing info to display
// @layer is the layer name
//
// ==== examples
//
// @data is an array of one hash built according to the following model:
// * minimal example of a hash representing a linestring:
//   item  {
//           name:         <intervention name>,  # This is what is called in the
//                                               # VisualizationHelper to build the legend if
//                                               # you wrote something like:
//                                               #   = visualization do |v|
//                                               #     - v.serie :stringline, my_array_of_hash_polyline
//                                               #     - v.polyline :name, :stringline
//                                               # :name being the @layer parameter the constructor requires.
//           shape:        stringline.shape,    # proper to the linestring. contains the actual linestring
//                                               # location as a Charta::Geometry linestring object.
//                                               # This is what is used to draw the linestring on the map
//  }
visualization.Polyline = class Polyline {

  constructor(layer, data, options) {
    this.layer = layer;
    this.data = data;
    if (options == null) { options = {}; }
    this.options = options;
    if (this.valid()) {
      console.log("Paths computed");
    } else {
      console.warn("Invalid paths");
    }
  }

  buildLayerGroup(widget, globalStyle) {
    if (globalStyle == null) { globalStyle = {}; }
    const group = [];
    // Reverse lng-lat to lat-lng for Leaflet
    for (var coordinate of Array.from(this.data[0].shape.coordinates)) {
      coordinate.reverse();
    }

    const latlngs = this.data[0].shape.coordinates;
    const lineLayer = new L.polyline(latlngs, this.options);
    group.push(lineLayer);
    return group;
  }

  // Build HTML legend for given paths computed layer
  buildLegend() {
    let html  = `<div class='leaflet-legend-item' id='legend-${this.layer.name}'>`;
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>";
    html += "<span class='leaflet-categories-items'>";
    html += "<span class='leaflet-categories-item'>";
    html += `<i class='leaflet-categories-sample' style='background-color: ${this.options.color};'></i>`;
    html += ` ${this.layer.label}`;
    html += "</span>";
    html += "</span>";
    html += "</div>";
    html += "</div>";
    return html;
  }

  // Check if paths are valid
  valid() {
    return true;
  }
};

visualization.registerLayerType("polyline", visualization.Polyline);