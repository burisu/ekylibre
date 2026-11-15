import L from 'leaflet';

// Image paths given by the layout (window.EkylibreAssets, digested by Propshaft)
const assets = window.EkylibreAssets || {};
const iconRetinaUrl = assets['map/pause-icon-2x.png'];
const iconUrl = assets['map/pause-icon.png'];

L.Icon.Pause = L.Icon.Default.extend({
    options: {
        iconUrl,
        iconRetinaUrl,
    },
});
