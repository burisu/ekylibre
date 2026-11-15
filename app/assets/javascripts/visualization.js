// Add sprockets directives below:
//= require core_ext
//= require visualization/color
//= require_self
//= require visualization/band
//= require visualization/bubbles
//= require visualization/categories
//= require visualization/choropleth
//= require visualization/heatmap
//= require visualization/path
//= require visualization/paths
//= require visualization/points
//= require visualization/point_group
//= require visualization/polyline
//= require visualization/simple

(function(V, $) {
  "use strict";

  V.layer = function(layer, data, options) {
    let type;
    if (this.layerTypes == null) { this.layerTypes = {}; }
    if (type = this.layerTypes[layer.type]) {
      return new type(layer, data, options);
    } else {
      console.warn(`Invalid layer type: ${layer.type}`);
      return null;
    }
  };

  V.registerLayerType = function(name, klass) {
    if (this.layerTypes == null) { this.layerTypes = {}; }
    return this.layerTypes[name] = klass;
  };

  // Generated colors in ruby
  // $ p = Proc.new{[37 * rand(7), 255].min.to_i.to_s(16).rjust(2, "0")}
  // $ (1..300).collect{|x| "##{p[]}#{p[]}#{p[]}"}.uniq
  V.colors = ["#00de00", "#6f006f", "#4ade94", "#004ab9", "#de6f4a", "#b9b925", "#00b994", "#25946f", "#de00b9", "#94006f", "#de6f94", "#252594", "#dede94", "#4a2594", "#940000", "#deb9de", "#00b9b9", "#00de94", "#25254a", "#6fde6f", "#4a0094", "#256f4a", "#6f4a25", "#4a4a00", "#b9006f", "#4a6f25", "#6f946f", "#009425", "#6f4ade", "#2525de", "#b9946f", "#b9b994", "#b9de94", "#de256f", "#b900b9", "#4a4a6f", "#4a2525", "#006fde", "#940025", "#250094", "#b900de", "#4ab9b9", "#00004a", "#6f6fde", "#256fde", "#b92594", "#6f944a", "#6f6f25", "#4ab9de", "#de2525", "#2525b9", "#944a94", "#b94a94", "#946f94", "#b94a6f", "#000094", "#4a6f6f", "#006f00", "#946f4a", "#00256f", "#6f4a6f", "#de6fb9", "#6fdeb9", "#de6f00", "#94b94a", "#94b994", "#6f6fb9", "#b925de", "#de2594", "#dede25", "#6f4a94", "#946f6f", "#de25de", "#b92525", "#6fde94", "#254a25", "#4adeb9", "#00deb9", "#b9b9b9", "#6f4a4a", "#256f25", "#25deb9", "#6f25de", "#94b925", "#b9254a", "#4ade25", "#4a006f", "#25006f", "#94de00", "#6fb925", "#259425", "#6f9425", "#944a00", "#25b9b9", "#25de4a", "#00254a", "#94254a", "#4a6f94", "#002500", "#6fdede", "#deb925", "#b9b9de", "#4a4a94", "#004a4a", "#25b994", "#6f6f00", "#b92500", "#b925b9", "#940094", "#2594de", "#4ade4a", "#949400", "#256f6f", "#de00de", "#6fde25", "#4a6fde", "#4a4ab9", "#deb96f", "#6f0025", "#00b925", "#0000b9", "#254a94", "#4a25b9", "#b9004a", "#b9de00", "#6f254a", "#6f2500", "#94b96f", "#25de00", "#b99425", "#b90025", "#0094b9", "#4ab925", "#4ab96f", "#6fde00", "#b9b96f", "#94b9b9", "#de4a6f", "#4a2500", "#de0000", "#4a4a4a", "#259494", "#9400b9", "#b9deb9", "#254a00", "#0000de", "#dede4a", "#94dede", "#94de25", "#4a9494", "#4a94de", "#6fb9b9", "#dede00", "#b9256f", "#de9494", "#009494", "#006f4a", "#94944a", "#4ab900", "#6f6f4a", "#b99494", "#6f004a", "#4a256f", "#00b9de", "#b99400", "#00b96f", "#deb9b9", "#4a6f00", "#000025", "#00006f", "#00de4a", "#b96f94", "#6fb9de", "#946fde", "#deb900", "#004ade", "#254ab9", "#25de6f", "#94deb9", "#b994de", "#004a25", "#94256f", "#250025", "#6f6f6f", "#4a944a", "#4a25de", "#00b94a", "#4a4a25", "#9400de", "#94004a", "#4a94b9", "#94de94", "#6f256f", "#6fb900", "#b9944a", "#de94de", "#944a25", "#6f2594"];

  $.widget("ui.visualization", {
    options: {
      box: {
        height: 400,
        width: null
      },
      backgrounds: {},
      overlays: {},
      controls: {},
      series: {},
      controlDefaults: {
        fullscreen: {
          position: 'topleft',
          title: I18n.t("front-end.leaflet.fullscreenTitle")
        },
        geocoder: {
          collapsed: true,
          position: 'topright',
          text: 'Locate',
          bounds: null,
          email: null
        },
        layerSelector: {
          collapsed: true,
          position: 'topright',
          autoZIndex: true
        },
        scale: {
          position: 'bottomleft',
          maxWidth: 200,
          metric: true,
          imperial: false,
          updateWhenIdle: false
        },
        zoom: {
          position: 'topleft',
          zoomInText: '',
          zoomInTitle: I18n.t("front-end.leaflet.zoomInTitle"),
          zoomOutText: '',
          zoomOutTitle: I18n.t("front-end.leaflet.zoomOutTitle")
        }
      },
      layers: {},
      layerDefaults: {
        band: {
          stroke: true,
          color: "#333333",
          weight: 1,
          opacity: 1,
          fill: true,
          fillColor: "blue",
          fillOpacity: 1,
          round: 5,
          startColor: '#FFFFFF',
          stopColor: '#910000',
          levelNumber: 7
        },
        bubbles: {
          stroke: true,
          color: "#333333",
          weight: 1,
          opacity: 1,
          fill: true,
          fillColor: "orange",
          fillOpacity: 1
        },
        categories: {
          stroke: true,
          color: "#333333",
          weight: 1,
          opacity: 1,
          fill: true,
          fillOpacity: 1
        },
        choropleth: {
          stroke: true,
          color: "#333333",
          weight: 1,
          opacity: 1,
          fill: true,
          fillColor: "blue",
          fillOpacity: 1,
          round: 5,
          startColor: '#FFFFFF',
          stopColor: '#910000',
          levelNumber: 7
        },
        simple: {
          stroke: true,
          color: "#333333",
          weight: 1,
          opacity: 1,
          fill: true,
          fillColor: "green",
          fillOpacity: 1
        },
        optional: {
          stroke: true,
          color: "#333333",
          weight: 1,
          opacity: 1,
          fill: true,
          fillColor: "#CBCFFB",
          fillOpacity: 0.5,
          zoomGuidance: I18n.t("front-end.leaflet.zoomGuidance")
        },
        paths: {
          stroke: true,
          color: "#333333",
          weight: 2,
          opacity: 0.2,
          fill: true,
          fillOpacity: 1
        },
        path: {
          stroke: true,
          color: "#333333",
          weight: 3,
          opacity: 1,
          fill: true,
          fillOpacity: 1,
          fillColor: "#333333",
          radius: 3
        },
        points: {
          stroke: true,
          color: "#333333",
          weight: 2,
          opacity: 1,
          fill: true,
          fillOpacity: 1,
          radius: 5
        },
        point_group: {
          stroke: true,
          color: "#333333",
          weight: 2,
          opacity: 1,
          fill: true,
          fillOpacity: 1,
          radius: 5
        }
      },
      map: {
        scrollWheelZoom: false,
        zoomControl: false,
        attributionControl: true,
        setDefaultBackground: false,
        setDefaultOverlay: false,
        dragging: true,
        touchZoom: true,
        doubleClickZoom: true,
        boxZoom: true,
        tap: true
      },
      view: {
        center:[],
        zoom : 13,
        maxZoom: 25,
        minZoom:2
      },
      colors: V.colors
    },

    _create() {
      let opts;
      $.extend(true, this.options, this.element.data("visualization"));
      this.mapElement = $("<div>", {class: "map"}).appendTo(this.element);

      this.map = L.map(this.mapElement[0], this.options.map);
      this.layers = [];

      if (this.options.map.setDefaultBackground) {
        opts = {};
        if (this.options.backgrounds.attribution != null) { opts['attribution'] = this.options.backgrounds.attribution; }
        opts['minZoom'] = this.options.backgrounds.minZoom || this.options.view.minZoom;
        opts['maxZoom'] = this.options.backgrounds.maxZoom || this.options.view.maxZoom;
        if (this.options.backgrounds.subdomains != null) { opts['subdomains'] = this.options.backgrounds.subdomains; }
        if (this.options.backgrounds.tms) { opts['tms'] = true; }

        const backgroundLayer = L.tileLayer(this.options.backgrounds.url, opts);
        backgroundLayer.addTo(this.map);
      }

      if (this.options.map.setDefaultOverlay) {
        opts = {};
        if (this.options.overlays.attribution != null) { opts['attribution'] = this.options.overlays.attribution; }
        opts['minZoom'] = this.options.overlays.minZoom || this.options.view.minZoom;
        opts['maxZoom'] = this.options.overlays.maxZoom || this.options.view.maxZoom;
        if (this.options.overlays.subdomains != null) { opts['subdomains'] = this.options.overlays.subdomains; }
        if ((this.options.overlays.opacity != null) && !isNaN(this.options.overlays.opacity)) { opts['opacity'] = (this.options.overlays.opacity / 100).toFixed(1); }
        if (this.options.overlays.tms) { opts['tms'] = true; }

        const OverlayLayer = L.tileLayer(this.options.overlays.url, opts);
        OverlayLayer.addTo(this.map);
      }

      this.ghostLabelCluster = L.ghostLabelCluster({type: 'number', innerClassName: 'leaflet-ghost-label-collapsed'});
      this.ghostLabelCluster.addTo(this.map);

      this.layersScheduler = L.layersScheduler();
      this.layersScheduler.addTo(this.map);

      this._resize();
      this._refreshView();
      this._refreshControls();

      this._bindOverlays();

      this.async_loading();
      if (!this.options.asyncUrl) { return this.optionalDataLoading(); }
    },

    async_loading() {
      if (this.options.asyncUrl == null) { return; }

      return $.ajax({
        method: 'GET',
        dataType: 'json',
        url: this.options.asyncUrl,
        beforeSend: () => {
          this.dynamic_loading = new L.Control({position: "bottomleft"});
          this.dynamic_loading.onAdd = map => {
            return L.DomUtil.create('div', 'leaflet-dynamic loading');
          };
          return this.map.addControl(this.dynamic_loading);
        },
        success: data => {
          $.extend(true, this.options, data);
          this._refreshControls();
          this.optionalDataLoading();
          return this.map.fire("async-layers-loaded");
        },
        error: () => {
          const dynamic_error = new L.Control({position: "bottomleft"});
          dynamic_error.onAdd = map => {
            return L.DomUtil.create('div', 'leaflet-dynamic error');
          };
          return this.map.addControl(dynamic_error);
        },
        complete: () => {
          return this.map.removeControl(this.dynamic_loading);
        }
      });
    },

    optionalDataLoading() {
      let url;
      if (!(url = this.options.optionalDataUrl)) { return; }

      const _refreshOptionalData = () => {
        const optionalLayerDisplayed = this._optionalLayersDisplayed()[0];

        if (this.zoom() >= 16) {
          return $.getJSON(url, {bounds: this.bounds(), required_value: optionalLayerDisplayed.requiredValue}, data => {
            for (var layer of Array.from(data.layers)) {
              this.options.series[layer.serie] = data.series[layer.serie];
              var serieData = this._getSerieData(layer.serie);
              var options = $.extend(true, {}, this.options.layerDefaults[layer.type], layer, {parent: this});
              var renderedLayer = V.layer(layer, serieData, options);
              if (!renderedLayer || !renderedLayer.valid()) { return; }

              $(this.controls.legendControl.getContainer()).find('.zoom-guidance').hide();
              var displayedOverlay = _.find(this.options.layers, ['reference', layer.reference]).overlay;
              var layerGroup = renderedLayer.buildLayerGroup(this, options);
              displayedOverlay.clearLayers();

              for (var _k in layerGroup) {
                var layr = layerGroup[_k];
                displayedOverlay.addLayer(layr);
              }
            }
          });

        } else {
          return (() => {
            const result = [];
            for (var layer of Array.from(_.filter(this.options.layers, ['type', 'optional']))) {
              $(this.controls.legendControl.getContainer()).find('.zoom-guidance').show();
              result.push(layer.overlay.clearLayers());
            }
            return result;
          })();
        }
      };


      return $.getJSON(url, data => {
        let layerToDisplay;
        $.extend(true, this.options.series, data.series);

        for (var layer of Array.from(data.layers)) {
          this.options.layers.push(layer);
          this._addLayer(layer, {});
          this.controls.layerSelector.addOverlay(layer.overlay, layer.label);
        }

        this.map.on('overlayadd', event => {
          if (this._optionalLayer(event.name)) {
            if (this._optionalLayersDisplayed().length === 1) { this.map.on('moveend', _refreshOptionalData); }
            this._optionalSiblings(event.name).forEach(layer => { if (this.map.hasLayer(layer.overlay)) { return delay(1, () => this.map.removeLayer(layer.overlay)); } });
            return delay(1, () => _refreshOptionalData());
          }
        });

        this.map.on('overlayremove', event => {
          if (!this._optionalLayersDisplayed().length) { return this.map.off('moveend', _refreshOptionalData); }
        });

        if (layerToDisplay = _.find(this.options.layers, { addToMap: true, type: 'optional' })) {
          return this.map.addLayer(layerToDisplay.overlay);
        }
      });
    },

    _destroy() {
      return this.mapElement.remove();
    },

    zoom(zoom) {
      if (zoom == null) { return this.map.getZoom(); }
      this.options.view.zoom = zoom;
      return this._refreshZoom();
    },

    height(height) {
      if (height == null) { return this.options.box.height; }
      this.options.view.box.height = height;
      return this._resize();
    },

    bounds() {
      return this.map.getBounds().toBBoxString();
    },

    rebuild() {
      this._destroy();
      return this._create();
    },

    layrs() {
      return this.layers;
    },

    mappo() {
      return this.map;
    },

    mappoElement() {
      return this.mapElement;
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

    // Retuns data from a serie found with the given name
    _getSerieData(name) {
      if (this.options.series[name] != null) {
        return this.options.series[name];
      } else {
        console.error(`Cannot find serie ${name}`);
        return alert(`Cannot find serie ${name}`);
      }
    },

    _optionalLayersDisplayed() {
      return _.filter(this.options.layers, layer => (layer.type === 'optional') && this.map.hasLayer(layer.overlay));
    },

    _optionalSiblings(layerName) {
      return _.reject(this.options.layers, layer => (layer.type !== 'optional') || (layer.label === layerName));
    },

    _optionalLayer(layerName) {
      return _.find(this.options.layers, { label: layerName, type: 'optional' });
    },

    // Displays all given controls
    _refreshControls() {
      let name;
      if (this.controls != null) {
        for (name in this.controls) {
          var control = this.controls[name];
          this.map.removeControl(control);
        }
      }
      this.controls = {};
      console.log("Refresh controls...", this.options.controls);
      if (!this.options || (this.options.controls == null)) {
        console.log("No controls...");
        return false;
      }
      const widget = this;
      return (() => {
        const result = [];
        for (name in this.options.controls) {
          var options = this.options.controls[name];
          console.log(`Add control ${name}...`);
          if (options !== false) {
            var functionName = `_add${name.camelize()}Control`;
            if ($.isFunction(widget[functionName])) {
              if (options === true) { options = {}; }
              result.push(widget[functionName].call(widget, options));
            } else {
              result.push(console.log(`Unknown control: ${name}`));
            }
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    },

    _addFullscreenControl(options) {
      options = $.extend(true, {}, this.options.controlDefaults.fullscreen, options);
      this.controls.fullscreen = new L.Control.FullScreen(options);
      this.map.addControl(this.controls.fullscreen);
      this.map.on("enterFullscreen", e => {
        return this.map.scrollWheelZoom.enable();
      });

      return this.map.on("exitFullscreen", e => {
        return this.map.scrollWheelZoom.disable();
      });
    },


    _addGeocoderControl(options) {
      options = $.extend(true, {}, this.options.controlDefaults.geocoder, options);
      this.controls.geocoder = new L.Control.OSMGeocoder(options);
      return this.map.addControl(this.controls.geocoder);
    },

    _addLayerSelectorControl(options) {
      let backgroundLayer, index, layer, opts;
      let baseLayers = {};
      const overlays = {};

      if (this.options.backgrounds.length > 0) {
        for (index = 0; index < this.options.backgrounds.length; index++) {
          layer = this.options.backgrounds[index];
          opts = {};
          if (layer.attribution != null) { opts['attribution'] = layer.attribution; }
          opts['minZoom'] = layer.minZoom || this.options.view.minZoom;
          opts['maxZoom'] = layer.maxZoom || this.options.view.maxZoom;
          if (layer.subdomains != null) { opts['subdomains'] = layer.subdomains; }
          if (layer.tms) { opts['tms'] = true; }

          backgroundLayer = L.tileLayer(layer.url, opts);
          baseLayers[layer.name] = backgroundLayer;
          if (layer.byDefault) { this.map.addLayer(backgroundLayer); }
        }
      } else {
        // no backgrounds, set defaults
        const backgrounds = ['OpenStreetMap.HOT',"OpenStreetMap.Mapnik", "Thunderforest.Landscape", "Esri.WorldImagery"];

        baseLayers = {};
        for (index = 0; index < backgrounds.length; index++) {
          layer = backgrounds[index];
          backgroundLayer = L.tileLayer.provider(layer);
          baseLayers[layer] = backgroundLayer;
          if (index === 0) { this.map.addLayer(backgroundLayer); }
        }
        this.map.fitWorld( { maxZoom: this.options.view.maxZoom } );
      }

      for (layer of Array.from(this.options.overlays)) {
        opts = {};
        if (layer.attribution != null) { opts['attribution'] = layer.attribution; }
        opts['minZoom'] = layer.minZoom || this.options.view.minZoom;
        opts['maxZoom'] = layer.maxZoom || this.options.view.maxZoom;
        if (layer.subdomains != null) { opts['subdomains'] = layer.subdomains; }
        if ((layer.opacity != null) && !isNaN(layer.opacity)) { opts['opacity'] = (layer.opacity / 100).toFixed(1); }
        if (layer.tms) { opts['tms'] = true; }

        overlays[layer.name] = L.tileLayer(layer.url, opts);
      }

      this.controls.legendControl = new L.control({position: "bottomright"});
      this.controls.legendControl.onAdd = map => L.DomUtil.create('div', 'leaflet-legend-control');
      this.map.addControl(this.controls.legendControl);

      L.DomUtil.addClass(this.controls.legendControl.getContainer(), 'leaflet-hidden-control');

      $('.leaflet-legend-control').on('click', function() {
        return $(this).find('#legend-activity').toggleClass('minified');
      });

      for (layer of Array.from(this.options.layers)) {
        this._addLayer(layer, overlays);
      }

      this.controls.layerSelector = new L.Control.Layers(baseLayers, overlays, this.options.controlDefaults.layerSelector);
      return this.map.addControl(this.controls.layerSelector);
    },

    _addLayer(layer, overlays) {
      let options;
      if (console.group !== undefined) {
        console.group(`Add layer ${layer.name} (${layer.type})...`);
      } else {
        console.log(`Add layer ${layer.name}...`);
      }
      if (options === true) { options = {}; }

      const data = this._getSerieData(layer.serie);
      options = $.extend(true, {}, this.options.layerDefaults[layer.type], layer, {parent: this});
      const renderedLayer = V.layer(layer, data, options);
      if (renderedLayer && renderedLayer.valid()) {
        // Build layer group
        const layerGroup = renderedLayer.buildLayerGroup(this, options);
        console.log(`${layer.name} layer rendered`, layerGroup);
        // Add layer overlay
        const overlayLayer = L.layerGroup(layerGroup);
        overlayLayer.name = layer.name;
        this.layers.push(layer);
        layer.overlay = (overlays[layer.label] = overlayLayer);
        if (layer.type !== 'optional') { this.map.addLayer(overlayLayer); }
        this.layersScheduler.insert(overlayLayer._leaflet_id);
        console.log(`${layer.name} layer added`);
        if (layer.type !== 'optional') {
          try {
            if (!!this.layerGroup) {
              this.layerGroup.addLayer(overlayLayer);
            } else {
              this.layerGroup = new L.featureGroup(layerGroup);
            }
            const bounds = this.layerGroup.getBounds();
            this.map.fitBounds(bounds);
            if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
              this.map.setZoom(18);
            }
          } catch (error) {}
        }

        
        // Add legend
        const legend = this.controls.legendControl.getContainer();
        legend.innerHTML += renderedLayer.buildLegend();
        L.DomUtil.removeClass(legend, 'leaflet-hidden-control');
      } else {
        console.warn(`Cannot add layer ${layer.type}`);
      }

      if (console.groupEnd !== undefined) { return console.groupEnd(); }
    },

    _addScaleControl(options) {
      options = $.extend(true, {}, this.options.controlDefaults.scale, options);
      this.controls.scale = new L.Control.Scale(options);
      return this.map.addControl(this.controls.scale);
    },

    _addZoomControl(options) {
      options = $.extend(true, {}, this.options.controlDefaults.zoom, options);
      this.controls.zoom = new L.Control.Zoom(options);
      return this.map.addControl(this.controls.zoom);
    },


    // Build a popup from given parameters. For now it only uses popup attribute of
    // a zone. After it will use a global template for all zone by default which can be
    // overriden with a local popup
    _bindPopup(layer, zone) {
      if (zone.popup == null) { return; }
      let popup = "";
      for (var block of Array.from(zone.popup)) {
        popup += `<div class='popup-${block.type}'>`;
        if (block.label != null) {
          popup += `<span class='popup-block-label'>${block.label}</span>`;
        }
        if (block.content != null) {
          popup += `<span class='popup-block-content'>${block.content}</span>`;
        } else if (block.value != null) {
          popup += `<span class='popup-block-value'>${block.value}</span>`;
        }
        popup += "</div>";
      }
      layer.bindPopup(popup);
      return layer;
    },

    _bindOverlays() {
      this.map.on("overlayadd", event => {
        this.layersScheduler.schedule(event.layer);
        console.log("Add legend control...");
        const legend = $(this.controls.legendControl.getContainer());
        legend.children(`#legend-${event.layer.name}`).show();
        legend.children(".first").removeClass("first");
        legend.children(":visible:first").addClass("first");
        return legend.removeClass("empty");
      });

      return this.map.on("overlayremove", event => {
        console.log("Remove legend control...");
        const legend = $(this.controls.legendControl.getContainer());
        legend.children(`#legend-${event.layer.name}`).hide();
        legend.children(".first").removeClass("first");
        legend.children(":visible:first").addClass("first");
        if (legend.children(":visible").length <= 0) { return legend.addClass("empty"); }
      });
    },

    _refreshView(view) {
      this._setDefaultView();
      if (this.options.view.center.length > 0) {
        return this.map.setView(this.options.view.center, this.options.view.zoom);
      }
    },

    _setDefaultView() {
      this.map.fitWorld();
      return this.map.setZoom(6);
    },

    _refreshZoom() {
      if (this.options.view.zoom != null) {
        return this.map.setZoom(this.options.view.zoom);
      }
    }
  }
  );

  $.loadVisualizations = function() {
    $("*[data-visualization]").each(function() {
      return $(this).visualization();
    });
    $(".refresh-locations[data-visualization]").each(function() {
      return refreshSensors($(this));
    });
  };

  // Needed to easily write setTimeout in CoffeeScript
  var delay = (time, method) => setTimeout(method, time);

  var refreshSensors = function(mapElement) {
    console.log("Test");
    if (mapElement.data("refreshTimeout") == null) {
      console.log("Setting timeout");
      const timeoutId = delay(10000, () => updateSensorLocations(mapElement));
      return mapElement.data("refreshTimeout", timeoutId);
    }
  };

  var updateSensorLocations = function(mapElement) {
    const sensorLayer = $(mapElement.visualization("layrs")).filter(function() { return this.name === "sensors"; })[0];
    const layers = sensorLayer.overlay._layers;
    const layer_keys = Object.keys(sensorLayer.overlay._layers);
    const marker_keys = $(layer_keys).filter(index => layers[layer_keys[index]].sensorId);
    const shadow_keys = $(layer_keys).filter(index => layers[layer_keys[index]].markerSensorId);
    const markers = $.map(marker_keys, (element, index) => layers[element]);
    const shadows = $.map(shadow_keys, (element, index) => layers[element]);
    $.get("/backend/sensors/last_locations", data => $(Object.keys(data)).each(function(index, sensorId) {
      let marker, shadow;
      marker = ((() => {
        const result = [];
        for (marker of Array.from(markers)) {             if (marker.sensorId === parseInt(sensorId)) {
            result.push(marker);
          }
        }
        return result;
      })())[0];
      shadow = ((() => {
        const result1 = [];
        for (shadow of Array.from(shadows)) {             if (shadow.markerSensorId === parseInt(sensorId)) {
            result1.push(shadow);
          }
        }
        return result1;
      })())[0];
      const newPos = new L.LatLng(data[sensorId].coordinates[1], data[sensorId].coordinates[0]);
      if ((marker != null) && (shadow != null)) {
        if (!marker.getLatLng().equals(newPos)) {
          marker.setLatLng(newPos);
          return shadow.setLatLng(newPos);
        }
      }
    }));
    console.log("Updated markers positions");
    const timeoutId = delay(10000, () => updateSensorLocations(mapElement));
    clearTimeout(mapElement.data("refreshTimeout"));
    return mapElement.data("refreshTimeout", timeoutId);
  };

  return $(document).on("turbo:load cocoon:after-insert cell:load dialog:show", $.loadVisualizations);

})(visualization, jQuery);
