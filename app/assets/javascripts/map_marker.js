(function($) {
  "use strict";

  $.widget("ui.mapmarker", {
    options: {
      box: {
        height: 400,
        width: null
      },
      background: {},
      marker: null,
      view: 'auto',
      controls: {
        zoom: {
          position: "topleft",
          zoomInText: "",
          zoomOutText: ""
        },
        scale: {
          position: "bottomright",
          imperial: false,
          maxWidth: 200
        }
      }
    },

    _create() {
      this.oldElementType = this.element.attr("type");
      this.element.attr("type", "hidden");

      $.extend(true, this.options, this.element.data("map-marker"));

      this.mapElement = $("<div>", {class: "map"})
        .insertAfter(this.element);
      this.map = L.map(this.mapElement[0], {
        maxZoom: 25,
        zoomControl: false,
        attributionControl: true
      }
      );

      this._resize();
      // console.log "resized"
      this._refreshBackgroundLayer();
      // console.log "backgrounded"
      this._refreshMarkerLayerGroup();
      // console.log "edited"
      this._refreshView();
      // console.log "viewed"
      return this._refreshControls();
    },
      // console.log "controlled"

    _destroy() {
      this.element.attr(this.oldElementType);
      return this.mapElement.remove();
    },

    background(background) {
      if (background == null) { return this.options.background; }
      this.options.background = background;
      return this._refreshBackgroundLayer();
    },

    edit(geojson) {
      if (geojson == null) { return this.options.edit; }
      this.options.edit = geojson;
      return this._refreshEditionLayerGroup();
    },

    view(view) {
      if (view == null) { return this.options.view; }
      this.options.view = view;
      return this._refreshView();
    },

    zoom(zoom) {
      if (zoom == null) { return this.map.getZoom(); }
      this.options.view.zoom = zoom;
      return this._refreshZoom();
    },

    height(height) {
      if (height == null) { return this.options.box.height(); }
      this.options.view.box.height = height;
      return this._resize();
    },

    _resize() {
      if (this.options.box != null) {
        if (this.options.box.height != null) {
          this.mapElement.height(this.options.box.height);
        }
        if (this.options.box.width != null) {
          this.mapElement.width(this.options.box.width);
        }
        return this._trigger("resize");
      }
    },

    _refreshBackgroundLayer() {
      if (this.backgroundLayer != null) {
        this.map.removeLayer(this.backgroundLayer);
      }
      if (this.options.background != null) {
        if (this.options.background.constructor.name === "Object") {
          this.backgroundLayer = L.tileLayer(this.options.background.url);
          this.backgroundLayer.addTo(this.map);
        }
        if (this.options.background.constructor.name === "Array") {
          let backgroundLayer, baseLayers, index, layer;
          if (this.options.background.length > 0) {
            baseLayers = {};
            for (index = 0; index < this.options.background.length; index++) {
              layer = this.options.background[index];
              var opts = {};
              if (layer.attribution != null) { opts['attribution'] = layer.attribution; }
              if (layer.minZoom != null) { opts['minZoom'] = layer.minZoom; }
              if (layer.maxZoom != null) { opts['maxZoom'] = layer.maxZoom; }
              if (layer.subdomains != null) { opts['subdomains'] = layer.subdomains; }
              if (layer.tms) { opts['tms'] = true; }

              backgroundLayer = L.tileLayer(layer.url, opts);
              baseLayers[layer.name] = backgroundLayer;
              if (layer.byDefault) { this.map.addLayer(backgroundLayer); }
            }
          } else {
            // no backgrounds, set defaults
            const back = ['OpenStreetMap.HOT',"OpenStreetMap.Mapnik", "Thunderforest.Landscape", "Esri.WorldImagery"];

            baseLayers = {};
            for (index = 0; index < back.length; index++) {
              layer = back[index];
              backgroundLayer = L.tileLayer.provider(layer);
              baseLayers[layer] = backgroundLayer;
              if (index === 0) { this.map.addLayer(backgroundLayer); }
            }
          }

          this.layerSelector = new L.Control.Layers(baseLayers);
          this.map.addControl(this.layerSelector);
        } else {
          console.log(`How to set background with ${this.options.background}?`);
          console.log(this.options.background);
        }
      }
      return this;
    },

    _refreshMarkerLayerGroup() {
      if (this.marker != null) {
        this.map.removeLayer(this.marker);
      }
      console.log(this.options.marker);
      this.marker = L.marker(this.options.marker, {
        draggable: true,
        riseOnHover: true
      }
      );
      const widget = this;
      this.marker.on("dragend", e => widget._saveUpdates());
      this.marker.addTo(this.map);
      this._saveUpdates();
      return this;
    },

    _refreshView(view) {
      if (view == null) { ({
        view
      } = this.options); }
      if (view === 'auto') {
        try {
          this._refreshView('show');
        } catch (error) {
          try {
            this._refreshView('edit');
          } catch (error1) {
            this._setDefaultView();
          }
        }
      } else if ((view === 'edit') || (view === 'show')) {
        this.map.fitBounds(this.marker.getLayers()[0].getBounds());
      } else if (view === 'default') {
        this._setDefaultView();
      } else if (view.center != null) {
        const center = L.latLng(view.center[0], view.center[1]);
        if (view.zoom != null) {
          this.map.setView(center, view.zoom);
        } else {
          this.map.setView(center, 18);
        }
      } else if (view.bounds != null) {
        this.map.fitBounds(view.bounds);
      } else {
        console.log(`How to set view with ${view}?`);
        console.log(view);
      }
      return this;
    },

    _setDefaultView() {
      this.map.fitWorld();
      return this.map.setZoom(18);
    },

    _refreshZoom() {
      if (this.options.view.zoom != null) {
        return this.map.setZoom(this.options.view.zoom);
      }
    },

    _refreshControls() {
      if (this.controls != null) {
        for (var name in this.controls) {
          var control = this.controls[name];
          this.map.removeControl(control);
        }
      }
      this.controls = {};
      if (this.options.controls.zoom !== false) {
        this.controls.zoom = new L.Control.Zoom(this.options.controls.zoom);
        this.map.addControl(this.controls.zoom);
      }
      if (this.options.controls.fullscreen !== false) {
        this.controls.fullscreen = new L.Control.FullScreen(this.options.controls.fullscreen);
        this.map.addControl(this.controls.fullscreen);
      }
      if (this.options.controls.scale !== false) {
        this.controls.scale = new L.Control.Scale(this.options.controls.scale);
        return this.map.addControl(this.controls.scale);
      }
    },

    _saveUpdates() {
      if (this.marker != null) {
        console.log(this.marker);
        this.element.val(JSON.stringify(this.marker.toGeoJSON()));
      }
      return true;
    }
  }
  );

  $.loadMapMarker = function() {
    $("*[data-map-marker]").each(function() {
      return $(this).mapmarker();
    });
  };

  return $(document).on("turbolinks:load cocoon:after-insert cell:load dialog:show", $.loadMapMarker);

})(jQuery);
