import L from 'leaflet';

// Image paths given by the layout (window.EkylibreAssets, digested by Propshaft)
const assets = window.EkylibreAssets || {};

delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: assets['leaflet/marker-icon-2x.png'],
    iconUrl: assets['leaflet/marker-icon.png'],
    shadowUrl: assets['leaflet/marker-shadow.png'],
});
