(function($) {
  "use strict";

  $.fn.mapsFromData = function() {
    $(this).each(function() {
      const mapElement = $(this);
      let options = {};
      let map = {};
      if (mapElement.prop("mapLoaded") !== true) {
        options = mapElement.data("map");

        // Box
        if (options.box) {
          if (options.box.height) { mapElement.height(options.box.height); }
          if (options.box.width) { mapElement.width(options.box.width); }
        }
        mapElement.css({display: "block"});
        map = L.map(mapElement[0], {
          maxZoom: 25,
          scrollWheelZoom: false,
          zoomControl: false,
          attributionControl: true
        }
        );
        mapElement.prop("map", map);
        if (options.background != null) {
          if (options.background.attribution != null) { opts['attribution'] = options.background.attribution; }
          if (options.background.minZoom != null) { opts['minZoom'] = options.background.minZoom; }
          if (options.background.maxZoom != null) { opts['maxZoom'] = options.background.maxZoom; }
          if (options.background.subdomains != null) { opts['subdomains'] = options.background.subdomains; }
          L.tileLayer(options.background.url, opts).addTo(map);
        } else {
          // Add an OpenStreetMap tile layer
          L.tileLayer.provider("OpenStreetMap.HOT").addTo(map);
        }

        $.each(options.geometries, function(index, value) {
          let layer = undefined;
          if (value.shape) {
            layer = L.GeoJSON.geometryToLayer(value.shape).setStyle({weight: 2});
            if (value.url) {
              layer.on("click", function(e) {
                window.location.assign(value.url);
              });
            }

            layer.addTo(map);
          }
        });

        // # Zoom
        // map.addControl L.control.zoom(
        //   position: "topleft"
        //   zoomInText: ""
        //   zoomOutText: ""
        // )
        // Scale
        map.addControl(new L.Control.Scale({
          imperial: false,
          maxWidth: 200
        })
        );

        // Bounding box
        if (options.view && options.view.boundingBox) { map.fitBounds(L.latLngBounds(options.view.boundingBox)); }

        mapElement.prop("mapLoaded", true);
      }
    });

  };

  $.loadMaps = function() {
    $("*[data-map]").mapsFromData();
  };

  $(document).on("turbo:load cocoon:after-insert cell:load", $.loadMaps);

  return true;
})(jQuery);
