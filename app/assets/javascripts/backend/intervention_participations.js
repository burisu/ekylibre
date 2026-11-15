(function(E, $) {
  'use strict';

  $(document).on('shown.bs.modal', '#working_times', function(event) {
    const participations = $(event.target).find('.participations .participation');

    if (participations.length > 0) {
      const element = $(event.target).find('.participations .participation').first();

      return E.interventionParticipations.changeWorkingPeriod(element);
    }
  });


  $(document).on('click', '#working_times .clear-period', function(event) {
    const element = $(event.target);
    const participation = element.closest('.participation');

    if (!participation.next().hasClass('participation')) {
      participation.next().remove();
    }

    const nextParticipation = E.interventionParticipations.nextParticipation(element);
    participation.remove();

    return E.interventionParticipations.changeWorkingPeriod(nextParticipation);
  });


  $(document).on("click", "#working_times .actions .action", function(event) {
    event.preventDefault();

    const element = $(this);
    const button_text = element.text().trim();
    const period_nature = element.attr('data-nature-period');

    const participationIndex = 0;
    const participationsCount = $('.participations .participation').length;
    const workingPeriodsAttributes = "intervention_participation[working_periods_attributes][" + participationsCount + "]";

    const newLine = $('<div class="participation"></div>');

    $(newLine).append('<input type="hidden" value="' + period_nature + '" name="working_period_nature" data-is-nature-hidden-field="true"></input>');
    $(newLine).append('<input type="hidden" name="working_period_started_at" data-is-hours-hidden-field="true"></input>');
    $(newLine).append('<input type="hidden" name="working_period_stopped_at" data-is-minutes-hidden-field="true"></input>');

    const participation_icon = $('<div class="participation-icon"></div>');
    $(participation_icon).append('<div class="picto picto-timelapse"></div>');
    $(participation_icon).append(button_text);
    $(newLine).append(participation_icon);

    $(newLine).append('<div class="participation-form"></div>');

    const hour_field = $('<div class="participation-field"></div>');
    $(hour_field).append('<input type="text" name="working_period_hours" class="participation-input" data-is-hours-field="true"></input>');
    $(hour_field).append('<span class="participation-field-label">H</span>');
    $(newLine).find('.participation-form').append(hour_field);

    const min_field = $('<div class="participation-field"></div>');
    $(min_field).append('<input type="text" name="working_period_minutes" class="participation-input" data-is-minutes-field="true"></input>');
    $(min_field).append('<span class="participation-field-label">Min</span>');
    $(newLine).find('.participation-form').append(min_field);

    let classes = "";
    if ($('#intervention_tool').val() === "true") {
      classes = "hidden";
    }

    const participationResult = $('<div class="participation-result"></div>');
    const results = $('<div class="results ' + classes + '"></div>');
    $(results).append('<span class="previous-working-date"></span>');
    $(results).append('<span> &#8594; </span>');
    $(results).append('<span class="next-working-date"></span>');
    $(participationResult).append(results);
    $(newLine).append(participationResult);

    const clearPeriod = $('<div class="clear-period"></div>');
    $(clearPeriod).append('<i class="picto picto-clear"></i>');
    $(newLine).append(clearPeriod);

    $('#working_times .participations').append(newLine);

  });


  $(document).on('click', '#validParticipationsForm', function(event) {
    const element = $(event.target);

    const participation = new Object();
    participation.id = $('#intervention_participation_id').val();
    participation.intervention_id = $('#intervention_participation_intervention_id').val();
    participation.product_id = $('#intervention_participation_product_id').val();
    participation.state = "done";

    const workingPeriods = [];
    const participations = $('.participation');
    let has_one_full_participation = false;

    $('.participation').each(function() {
      const workingPeriodNature = $(this).find('input[name="working_period_nature"]').val();

      if (workingPeriodNature !== "pause") {
        const workingPeriod = new Object();
        workingPeriod.id= $(this).find('input[name="working_period_id"]').val();
        workingPeriod.nature = workingPeriodNature;
        workingPeriod.started_at = $(this).find('input[name="working_period_started_at"]').val();
        workingPeriod.stopped_at = $(this).find('input[name="working_period_stopped_at"]').val();

        if ((workingPeriod.started_at !== "") && (workingPeriod.stopped_at !== "")) {
          has_one_full_participation = true;
        }

        return workingPeriods.push(workingPeriod);
      }
    });

    participation.working_periods_attributes = workingPeriods;
    const jsonParticipation = JSON.stringify(participation);

    const concernedProductField = $('.nested-fields .selector .selector-value[value="' + participation.product_id + '"]');
    const participationsCount = $('input[type="hidden"].intervention-participation').length;
    const existingParticipation = $('.intervention-participation[data-product-id="' + participation.product_id + '"]');

    if (existingParticipation.length > 0) {
      existingParticipation.val(jsonParticipation);
    } else {
      $(concernedProductField).closest('.nested-fields').append('<input type="hidden" class="intervention-participation" name="intervention[participations_attributes][' + participationsCount + ']" value=\'' + jsonParticipation + '\' data-product-id="' + participation.product_id  + '"></input>');
    }


    const nestedFieldBlock = concernedProductField.closest('.nested-fields');
    const productFieldPicto = nestedFieldBlock.find('.picto-timer-off');

    if (has_one_full_participation && (productFieldPicto.length === 1)) {
      productFieldPicto.removeClass('picto-timer-off');
      productFieldPicto.addClass('picto-timer');
    }

    this.workingTimesModal = new ekylibre.modal('#working_times');
    this.workingTimesModal.getModal().modal('hide');

    return E.interventionForm.displayCost(element);
  });


  $(document).on("keyup", '#working_times .participations input[type="text"]', function(event) {
    const element = $(event.target);

    if ($('#working_times #intervention_tool').length === 1) {
      E.interventionParticipations.changeCalculMode(false);
    }

    return E.interventionParticipations.changeWorkingPeriod(element);
  });


  $(document).on("click", '#participation_auto_calculate_equipments', function(event) {

    const isChecked = $(event.target).is(':checked');
    return E.interventionParticipations.changeCalculMode(isChecked);
  });


  E.interventionParticipations = {
    changeCalculMode(value) {
      return $('#intervention_auto_calculate_working_periods').val(value);
    },


    changeWorkingPeriod(element) {
      const date_format = I18n.ext.datetimeFormat.fullJsFormat();
      const participationsCount = $('.participations .participation').length;
      let participation = null;

      if (element.hasClass('participation')) {
        participation = element;
      } else {
        participation = element.closest(".participation");
      }


      const hours = participation.find("input[data-is-hours-field='true']").val();
      const minutes = participation.find("input[data-is-minutes-field='true']").val();

      let previousStartedAt = null;
      let newDate = null;

      if (this.firstParticipation(participation)) {
        previousStartedAt = new Date($('#intervention_started_at').val());
        newDate = this.calculNewDate(previousStartedAt.getTime(), hours, minutes);
      } else {
        const previousParticipation = this.previousParticipation(element);
        const stringDate = previousParticipation.find('.next-working-date').text();

        previousStartedAt = moment(stringDate, date_format)._d;

        newDate = this.calculNewDate(previousStartedAt, hours, minutes);
      }


      const formattedPreviousStartDate = moment(previousStartedAt).format(date_format);
      const formattedStoppedDate = moment(newDate).format(date_format);

      participation.find('.previous-working-date').text(formattedPreviousStartDate);
      participation.find('.next-working-date').text(formattedStoppedDate);

      participation.find('input[data-is-hours-hidden-field="true"]').val(formattedPreviousStartDate);
      participation.find('input[data-is-minutes-hidden-field="true"]').val(formattedStoppedDate);


      if (!this.lastParticipation(element)) {
        const nextParticipation = this.nextParticipation(element);
        return this.changeWorkingPeriod(nextParticipation);
      }
    },


    calculNewDate(startDate , hours, minutes) {
      const newDate = moment(startDate);
      newDate.add(hours, 'hours');
      return newDate.add(minutes, 'minutes');
    },

    previousParticipation(element) {
      const participation = element.closest('.participation');
      const previousElement = participation.prev();

      if (previousElement.hasClass('participation')) {
        return previousElement;
      } else {
        return previousElement.prev();
      }
    },

    nextParticipation(element) {
      const participation = element.closest('.participation');
      const nextElement = participation.next();

      if (nextElement.hasClass('participation')) {
        return nextElement;
      } else {
        return nextElement.next();
      }
    },

    firstParticipation(element) {
      return element.prev().hasClass('participations-header');
    },

    lastParticipation(element) {
      return this.nextParticipation(element).length === 0;
    }
  };


  return true;
})(ekylibre, jQuery);
