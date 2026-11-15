(function(E, $) {
  'use strict';

  return $(document).ready(function() {


    class PlantLandParcelSelector {
      static initClass() {
        this.prototype.ACTIVITY_PRODUCTION_PARAM_NAME = 'of_activity_production';
        this.prototype.WITH_ID_PARAM_NAME = 'with_id';
  
        this.prototype.PLANT_VALUE = 'plant';
        this.prototype.LAND_PARCEL_VALUE = 'land_parcel';
  
        this.prototype.PLANT_UNROLL_VALUE = 'is+plant+and+has+indicator+shape';
        this.prototype.LAND_PARCEL_UNROLL_VALUE = 'is+land_parcel+and+has+indicator+shape';
      }

      constructor() {}


      changeUnrollUrl(event, unrollElement, supportId = null, activityProduction = null) {
        const selectedValue = $(event.target).val();
        let unrollExpression = this.PLANT_UNROLL_VALUE;
        if (selectedValue === this.LAND_PARCEL_VALUE) { unrollExpression = this.LAND_PARCEL_UNROLL_VALUE; }

        const unrollRegex = /(unroll\?.*scope.*of_expression[^=]*)=([^&]*)(&?.*)/;
        let unrollPath = $(unrollElement).attr('data-selector');
        unrollPath = unrollPath.replace(unrollRegex, `$1=${ unrollExpression }$3`);

        const ofActivityProduction = unrollPath.includes(this.ACTIVITY_PRODUCTION_PARAM_NAME);
        const withId = unrollPath.includes(this.WITH_ID_PARAM_NAME);

        if (selectedValue === this.LAND_PARCEL_VALUE) {
          if (!ofActivityProduction) { $(unrollElement).attr('data-selector', unrollPath); }
          if (ofActivityProduction) { $(unrollElement).attr('data-selector', this._unrollPathWithScope(unrollPath, this.ACTIVITY_PRODUCTION_PARAM_NAME, supportId)); }
          $($(unrollElement)[0]).selector('value', supportId);

        } else if (selectedValue === this.PLANT_VALUE) {
          if (!withId) { $(unrollElement).attr('data-selector', unrollPath); }
          if (withId) { $(unrollElement).attr('data-selector', this._unrollPathWithScope(unrollPath, this.WITH_ID_PARAM_NAME, activityProduction)); }

          $(unrollElement).val(null);
          $(unrollElement).closest('.selector').find('.selector-value').val(null);
        }

        return $(unrollElement).trigger('selector:set');
      }


      _unrollPathWithScope(unrollPath, paramName, paramValue) {
        const unrollPathBegin = unrollPath.split(paramName)[0];
        const scope = `${ paramName }=${ paramValue }$3`;

        return unrollPathBegin + scope;
      }
    }
    PlantLandParcelSelector.initClass();


    return E.PlantLandParcelSelector = PlantLandParcelSelector;});

})(ekylibre, jQuery);
