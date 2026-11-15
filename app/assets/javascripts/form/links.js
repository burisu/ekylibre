(function($, E) {

  E.links = {
    // Adds change event on in order to update a link
    setUpdateTriggers() {
      const links = $(this);
      return links.each(function() {
        const link = $(this);
        const triggerSelector = link.data('update-link-with');
        return $(triggerSelector).change(function() {
          let url = link.attr('href');
          const triggeredInput = $(this);
          const id = triggeredInput.attr('name');
          const value = triggeredInput.val();
          const regExp = new RegExp(`(\\?|\\&)(${id})\\=([^&]+)`);

          if (url.match(regExp)) {
            url = url.replace(regExp, `$1$2=${value}`);
          } else {
            if (url.indexOf('?') < 0) { url += '?'; } else { url += '&'; }
            url += `${id}=${value}`;
          }
          return link.attr('href', url);
        });
      });
    },

    // Extracts a list of IDs from an URL parameter
    getIdsFromUrl(url, paramName) {
      if (url.indexOf('?') > 1) {
        const parametersWithValues = url.split('?')[1];
        const parametersWithValuesArray = parametersWithValues.split('&');
        for (var parameterWithValue of Array.from(parametersWithValuesArray)) {
          var name = parameterWithValue.split('=')[0];
          if (name === paramName) {
            var parameterValue = parameterWithValue.split('=')[1];
            if (parameterValue !== '') {
              return parameterValue.split(',').map(Number);
            }
          }
        }
      }
      return [];
    },


    // Updates IDs list with given un/checked checkbox and existing IDs list
    addOrRemoveIdFromIds(checkbox, ids, checkboxes) {
      let id, index;
      let attrId = checkbox.closest('tr').attr('id');
      if ((attrId !== undefined) && (attrId != null)) {
        id = parseInt(attrId.substring(1));
        if (checkbox.is(':checked')) {
          ids.push(id);
        } else {
          index = ids.indexOf(id);
          ids.splice(index, 1);
        }
      } else if (checkbox.is('*[data-list-selector="all"]')) {
        const checked = checkbox.is(':checked');
        checkboxes.each(function() {
          checkbox = $(this);
          attrId = checkbox.closest('tr').attr('id');
          if ((attrId !== undefined) && (attrId != null)) {
            id = parseInt(attrId.substring(1));
            if (checked) {
              return ids.push(id);
            } else {
              index = ids.indexOf(id);
              return ids.splice(index, 1);
            }
          }
        });
      }
      return ids;
    },


    // Updates URL with given IDs
    updateUrlWithIds(url, ids, paramName) {
      if (url.indexOf(paramName) < 0) {
        if (url.indexOf('?') < 0) { url += '?'; } else { url += '&'; }
        url += `${paramName}=${ids.join(',')}`;
      } else {
        let idsArray = url.split(paramName)[1];
        let optionalParameters = "";
        if (idsArray.indexOf('&') > 0) {
          const indexOptionalParameters = idsArray.indexOf('&');
          optionalParameters = idsArray.substring(index);
          idsArray = idsArray.split('&')[0];
        }

        idsArray = idsArray.substring(1);

        let paramToSplit = "";
        if (url.indexOf(`?${paramName}`) > 0) { paramToSplit = '?'; } else { paramToSplit += '&'; }
        paramToSplit += paramName;
        url = url.split(`${paramToSplit}`)[0];

        if (url.indexOf('?') < 0) { url += '?'; } else { url += '&'; }
        url += `${paramName}=${ids.join(',')}`;
        url += optionalParameters;
      }
      return url;
    },

    // Adds
    handleShowActions(link, count) {
      const show_mode = link.data('show-if-checked');
      const action_form = link.closest('.action-form');
      if (show_mode === 'any') {
        if (count === 0) {
          return action_form.hide();
        } else {
          return action_form.show();
        }

      } else if (show_mode === 'two-or-more') {
        if (count >= 2) {
          const totalDebit = $('#total-debit').text();
          const totalCredit = $('#total-credit').text();
          if (totalCredit !== totalDebit) {
            return action_form.show();
          } else {
            return action_form.hide();
          }
        } else {
          return action_form.hide();
        }
      }
    },

    handleEnableActions(link, count) {
      const show_mode = link.data('enable-if-checked');
      const action_form = link.closest('.action-form');
      if (show_mode === 'any') {
        if (count === 0) {
          return action_form.addClass('disabled');
        } else {
          return action_form.removeClass('disabled');
        }

      } else if (show_mode === 'two-or-more') {
        if (count >= 2) {
          const totalDebit = $('#total-debit').text();
          const totalCredit = $('#total-credit').text();
          if (totalCredit !== totalDebit) {
            return action_form.removeClass('disabled');
          } else {
            return action_form.addClass('disabled');
          }
        } else {
          return action_form.addClass('disabled');
        }
      }
    },



    // Adds
    addEventOnCheckboxes() {
      const links = $(this);
      return links.each(function() {
        const link = $(this);
        const paramName = link.attr('name');
        const checkboxes = $(link.data('complete-link-with-checked-row-ids'));

        return checkboxes.change(function() {
          let url = link.attr('href');
          let ids = E.links.getIdsFromUrl(url, paramName);
          ids = E.links.addOrRemoveIdFromIds($(this), ids, checkboxes);
          url = E.links.updateUrlWithIds(url, ids, paramName);
          link.attr('href', url);
          E.links.handleShowActions(link, ids.length);
          return E.links.handleEnableActions(link, ids.length);
        });
      });
    }
  };


  $(document).behave('load', 'a[data-update-link-with]', E.links.setUpdateTriggers);

  $(document).behave('load', 'a[data-complete-link-with-checked-row-ids]', E.links.addEventOnCheckboxes);

  $(document).on('after-refresh-list', 'a[data-update-link-with]', E.links.setUpdateTriggers);

  return $(document).on('after-refresh-list', 'a[data-complete-link-with-checked-row-ids]', E.links.addEventOnCheckboxes);

})(jQuery, ekylibre);
