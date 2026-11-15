(function(E, $) {
  "use strict";

  $(document).ready(() => $('.wice-grid-container').each((index, domElement) => E.wice_grid_settings.addColumnsToToolbar(domElement)));

  $(document).on('mouseover', '.wice-grid-toolbar .parent', function() {
    return E.wice_grid_settings.setToolbarUp($(this));
  });

  $(document).on('click', '.wice-grid-toolbar .wice-grid-columns-selector', function() {
    if ($(this).hasClass('checked')) {
      $(this).addClass('unchecked');
      $(this).removeClass('checked');

      $('thead #' + $(this).data('corresponding-column')).addClass('hidden');
      $('tbody #' + $(this).data('corresponding-column')).addClass('hidden');

      return E.wice_grid_settings.saveColumnPreference($(this).data('corresponding-column'), false);
    } else {
      $(this).addClass('checked');
      $(this).removeClass('unchecked');

      $('thead #' + $(this).data('corresponding-column')).removeClass('hidden');
      $('tbody #' + $(this).data('corresponding-column')).removeClass('hidden');

      return E.wice_grid_settings.saveColumnPreference($(this).data('corresponding-column'), true);
    }
  });


  class Settings {
    setToolbarUp(container) {
      const toolbar = this.toolbar(container);

      if ($(toolbar).hasClass('menu-up')) {
        const dropdownColumnsMenu = this.toolbar(container).find('.dropdown-columns-menu');
        const dropdownHeight = $(dropdownColumnsMenu).height();

        return $(dropdownColumnsMenu).attr('style', 'top: -' + dropdownHeight + "px;");
      }
    }

    toolbar(container) {
      return $(container).closest('.cobble').find('.wice-grid-toolbar');
    }

    table(container) {
      return $(container).find('.wice-grid.table');
    }

    columns(container) {
      return this.table(container).find('.wice-grid-title-row th');
    }

    addColumnsToToolbar(container) {
      const self = this;
      return this.columns(container).each(function(index, column) {
        const newLine = $(document.createElement('A'));
        newLine.append('<i></i>');
        newLine.append('<span>' + $(column).text() + '</span>');

        let checkedColumn = 'checked';
        if ($(column).hasClass('hidden')) {
          checkedColumn = 'unchecked';
        }

        const newColumnLine = $(document.createElement('LI'));
        newColumnLine.addClass('wice-grid-columns-selector ' + checkedColumn);
        newColumnLine.attr('data-corresponding-column', $(column).attr('id'));
        newColumnLine.append(newLine);

        return self.toolbar(container).find('.dropdown-columns-menu').append(newColumnLine);
      });
    }

    saveColumnPreference(id, value) {
      const url = '/backend/users/wice_grid_preferences/save_column';

      const preference = {};
      preference['name'] = `wice_grid_column.${id}`;
      preference['value'] = value;
      preference['nature'] = 'boolean';

      return $.ajax({
        url,
        method: 'POST',
        dataType: "json",
        data: {
          preference
        },
        success: (data, status, request) => {}
      });
    }
  }


  E.wice_grid_settings = new Settings();

  return true;
})(ekylibre, jQuery);
