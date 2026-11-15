// Modules exposed as globals to the legacy scripts (app/assets/javascripts),
// loaded before them (see ApplicationHelper#javascript_tags)
import 'pages';

import { StateBadgeSet, StateSet } from 'components/state_badge_set';
import { geocodingInput } from 'components/geocodingInput';
import { ajax, customFetch } from 'services/ajax';
import RBush from 'rbush';
import moment from 'moment';
import { notify, setup } from 'services/notification';
import { enableDatePicker, enableDateRangePicker, enableDatetimePicker, enableTimePicker } from 'lib/flatpickr';
import { open, openFromElementDataAttributes, openRemote } from 'components/modal';
import { I18n } from 'services/i18n';
import * as Behave from 'services/behave';
import { delegateListener, onDomReady, onElementDetected } from 'lib/domEventUtils';
import autosize from 'autosize';
import { openDialog } from 'components/dialog';
import _ from 'lodash';
import L from 'leaflet';
import 'leaflet-draw';
import 'lib/leaflet/default-icon';
import { MasterProductionService } from 'services/masterProductionService';
import { VarietyService } from 'services/varietyService';
import { CultivableZoneService } from 'services/cultivableZoneService';
import { CampaignService } from 'services/campaignService';
import { ProductService } from 'services/productService';
import { GeocodingService } from 'services/GeocodingService';

import 'components/map/pause-icon';

export let Ekylibre = {
    ajax,
    delegateListener,
    Dialog: { open: openDialog },
    fetch: customFetch,
    forms: {
        date: { enableDatePicker, enableDateRangePicker, enableDatetimePicker, enableTimePicker },
    },
    notification: { setup, notify },
    onElementDetected,
    onDomReady,
    MasterProductionService,
    VarietyService,
    CultivableZoneService,
    CampaignService,
    ProductService,
    GeocodingService,
};

export let globals = {
    Behave,
    calcul: {},
    DynamicModal: {
        open,
        openFromElementDataAttributes,
        openRemote,
    },
    golumn: {},
    mapeditor: {},
    StateBadgeSet,
    StateSet,
    geocodingInput,
    visualization: {},
};

export let vendors = {
    _,
    autosize,
    I18n,
    moment,
    RBush,
    L,
};

Object.assign(window, vendors, globals);
window.ekylibre = Ekylibre;
