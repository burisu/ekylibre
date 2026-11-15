(function(E, $) {
  "use strict";

  let BankReconciliation;
  E.bankReconciliation = null;

  $(function() {
    const precision = parseInt($(".reconciliation-list").data('currency-precision'));
    E.bankReconciliation = new BankReconciliation(precision);

    E.bankReconciliation.initialize();

    const position_space = new RegExp(".*scroll_to=(\\d+).*");
    const position = position_space.exec(location.search);
    if (position) {
      const scrollTo = $(`[data-type=bank_statement_item][data-id=${position[1]}]`).parents('.date-section')[0];
      return $('.list').scrollTop(scrollTo.offsetTop - $('.list')[0].offsetTop);
    }
  });

  $(document).on("click", ".reconciliation-item[data-type=bank_statement_item] a#delete", function() {
    // Remove bank statement item
    const button = $(this);
    const bankStatementItem = E.bankReconciliation.closestLine(button);
    E.bankReconciliation.destroyLine(bankStatementItem);
    return false;
  });

  $(document).on("click", ".reconciliation-item:not(.selected)", function(event) {
    // Select line
    if ($(event.target).is("input,a,form")) { return; }
    return E.bankReconciliation.selectLine($(this));
  });

  $(document).on("click", ".reconciliation-item.selected", function(event) {
    // Deselect line
    if ($(event.target).is("input,a")) { return; }
    return E.bankReconciliation.deselectLine($(this));
  });

  $(document).on("click", ".reconciliation-item a#clear", function(event) {
    // Clear reconciliation letter
    event.stopPropagation();
    const button = $(this);
    const line = E.bankReconciliation.closestLine(button);
    E.bankReconciliation.clearReconciliationLetterFromLine(line);
    return false;
  });

  $(document).on("click", ".reconciliation-item[data-type=journal_entry_item] a#complete", function() {
    // Complete journal entry items
    const button = $(this);
    const line = E.bankReconciliation.closestLine(button);
    E.bankReconciliation.completeJournalEntryItems(line);
    return false;
  });

  $(document).on("confirm:complete", "#reset_reconciliation", function(e, response) {
    if (response) {
      return E.bankReconciliation.clearAllReconciliationLetters();
    }
  });

  $(document).on("click", "#auto_reconciliation", () => // Automatic reconciliation
  E.bankReconciliation.autoReconciliate());

  $(document).on("change", "#hide-lettered", () => E.bankReconciliation.uiUpdate());

  $(document).on("change", "#set_period", function(event) {
    const matches = event.target.value.match(/\d+-\d+-\d+/g);
    if (matches.length !== 2) {
      return;
    }

    const start = moment(matches[0]).format('YYYY-MM-DD');
    const end = moment(matches[1]).format('YYYY-MM-DD');

    const url = new URL(location.href);
    url.searchParams.set('period_start', start);
    url.searchParams.set('period_end', end);

    const urlStr = url.toString();

    if (location.href !== urlStr) {
      return location.href = urlStr;
    }
  });


  return BankReconciliation = class BankReconciliation {
    constructor(precision) {
      this.precision = precision;
    }

    initialize() {
      return this.uiUpdate();
    }

    // Accessors

    closestLine(element) {
      return element.closest(this._lines());
    }

    //# NEW BANK STATEMENT ITEMS

    // Add bank statement items

    createBankStatementItem(date) {
      if (this._addBankStatementItemInDateSection(date)) { return; }
      //@_insertDateSection date
      return this._addBankStatementItemInDateSection(date);
    }

    _addBankStatementItemInDateSection(date) {
      const formatedDate = moment(date).format("YYYY-MM-DD");
      const dateSection = $(`p[data-date=${formatedDate}]`).closest('.date-section');
      dateSection.removeClass('hidden');
      const newItemButton = dateSection.children(".date-header").find('a');
      if (!newItemButton.length) { return false; }
      newItemButton.click();
      return true;
    }

    _insertDateSection(date) {
      const template = $($(".date-header p[data-date=tmpl-date]")[0]).parents(".date-section")[0].outerHTML;
      let html = template.replace(/tmpl-date/g, date);
      html = $(html).removeClass('hidden')[0].outerHTML;
      const dateSections = $(".date-header p[data-date!=tmpl-date]");
      const nextDateSection = dateSections.filter(function() { return $(this).data("date") > date; }).first();
      if (nextDateSection.length) {
        return nextDateSection.parent(".date-section").before(html);
      } else {
        return $(".reconciliation-list .totals").before(html);
      }
    }

    // Add bank statement items from selected journal entry items

    completeJournalEntryItems(clickedLine) {
      const params =
        {name: clickedLine.find('.name').first().html()};

      const selectedJournalEntryItems = this._lines().filter("[data-type=journal_entry_item].selected");
      const debit = selectedJournalEntryItems.find(".debit").sum();
      const credit = selectedJournalEntryItems.find(".credit").sum();
      const balance = debit - credit;
      if (balance > 0) {
        params.credit = balance;
      } else {
        params.debit = -balance;
      }

      const date = this._dateForLine(clickedLine);
      const buttonInDateSection = $(`.date-header p[data-date=${date}]`).parent(".date-header").find('a');
      buttonInDateSection.one("ajax:beforeSend", (event, xhr, settings) => (() => {
        const result = [];
        for (var key in params) {
          var value = params[key];
          result.push(settings.url += `&bank_statement_item[${key}]=${value}`);
        }
        return result;
      })());
      buttonInDateSection.one("ajax:complete", (event, xhr, status) => {
        // use ajax:complete to ensure elements are already added to the DOM
        if (status !== "success") { return; }
        return this.uiUpdate();
      });
      return buttonInDateSection.click();
    }

    // Remove bank statement items

    destroyLine(line) {
      if (line.data('id') != null) { return this._deleteLine(line); } else { return this._destroyBankStatementItem(line); }
    }

    _destroyBankStatementItem(bankStatementItem) {
      this._removeLine(bankStatementItem);
      this._clearLinesWithReconciliationLetter(this._reconciliationLetter(bankStatementItem));
      this._reconciliateSelectedLinesIfValid();
      return this.uiUpdate();
    }

    _removeLine(line) {
      const form = line.parents('form');
      const parent = line.parents('.date-section');
      const siblings = parent.find('.reconciliation-item');
      line.deepRemove();
      if (form != null) { form.deepRemove(); }
      if (siblings.length <= 1) {
        return parent.addClass('hidden');
      }
    }

    _isDateSection(line) {
      return line.hasClass("date-header");
    }

    // Select/deselect lines

    selectLine(line) {
      if (this._isLineReconciliated(line) || isNaN(this._idForLine(line)) || this._isLineLocked(line)) { return; }
      line.addClass("selected");
      this._reconciliateSelectedLinesIfValid();
      return this.uiUpdate();
    }

    deselectLine(line) {
      line.removeClass("selected");
      this._reconciliateSelectedLinesIfValid();
      return this.uiUpdate();
    }

    // Reconciliation methods

    clearAllReconciliationLetters() {
      const letters = [];
      this._reconciliatedLines().each((i, e) => {
        const letter = this._reconciliationLetter($(e));
        if (!letters.includes(letter)) { return letters.push(letter); }
      });
      for (var letter of Array.from(letters)) { this._clearLinesWithReconciliationLetter(letter); }
      return this.uiUpdate();
    }

    clearReconciliationLetterFromLine(line) {
      const letter = this._reconciliationLetter(line);
      if (!letter) { return; }
      this._clearLinesWithReconciliationLetter(letter);
      return this.uiUpdate();
    }

    autoReconciliate() {
      const notReconciliated = this._notReconciliatedLines();
      const bankItems = notReconciliated.filter("[data-type=bank_statement_item]");
      const journalItems = notReconciliated.filter("[data-type=journal_entry_item]");

      bankItems.each((i, e) => {
        const date = this._dateForLine($(e));
        const credit = this._creditForLine($(e));
        const debit = this._debitForLine($(e));
        const similarBankItems = this._filterLinesBy(bankItems, {date, credit, debit});
        if (similarBankItems.length !== 1) { return; }
        const similarJournalItems = this._filterLinesBy(journalItems, {date, credit: debit, debit: credit});
        if (similarJournalItems.length !== 1) { return; }
        return this._letterItems($(e).add(similarJournalItems));
      });
      return this.uiUpdate();
    }

    _reconciliateSelectedLinesIfValid() {
      const selected = this._lines().filter(".selected");
      if (!this._areLineValidForReconciliation(selected)) { return; }
      return this._letterItems(selected);
    }

    _areLineValidForReconciliation(lines) {
      if (!lines.length) { return false; }
      const journalEntryItems = lines.filter("[data-type=journal_entry_item]");
      const journalEntryItemsDebit = journalEntryItems.find(".debit").sum();
      const journalEntryItemsCredit = journalEntryItems.find(".credit").sum();
      const journalEntryItemsBalance = Math.round((journalEntryItemsDebit - journalEntryItemsCredit) * Math.pow(10, this.precision));
      const bankStatementItems = lines.filter("[data-type=bank_statement_item]");
      const bankStatementItemsDebit = bankStatementItems.find(".debit").sum();
      const bankStatementItemsCredit = bankStatementItems.find(".credit").sum();
      const bankStatementItemsBalance = Math.round((bankStatementItemsDebit - bankStatementItemsCredit) * Math.pow(10, this.precision));
      return journalEntryItemsBalance === -bankStatementItemsBalance;
    }

    _clearLinesWithReconciliationLetter(letter) {
      if (!letter) { return; }
      return this._unletterItems(letter);
    }

    _reconciliatedLines() {
      return this._lines().filter((i, e) => this._isLineReconciliated($(e)));
    }

    _notReconciliatedLines() {
      return this._lines().filter((i, e) => !this._isLineReconciliated($(e)));
    }

    _isLineReconciliated(line) {
      return !!this._reconciliationLetter(line);
    }

    _isLineLocked(line) {
      return $(line).find('.locked i').length === 1;
    }

    _linesWithReconciliationLetter(letter) {
      return this._lines().filter((i, e) => this._reconciliationLetter($(e)) === letter);
    }

    _reconciliationLetter(line) {
      return line.find(".details .letter").text();
    }

    // UI UPDATING

    uiUpdate() {
      this._showOrHideClearButtons();
      this._showOrHideCompleteButtons();
      this._showOrHideNewPaymentButtons();
      return this._showOrHideReconciliatedLines();
    }

    _showOrHideClearButtons() {
      this._reconciliatedLines().each((_index, line) => {
        const letter = this._reconciliationLetter($(line));
        const bankStatementId = $(line).data('bank-statement-id') || $(`.reconciliation-item[data-type='bank_statement_item'][data-letter='${letter}']`).first().data('bank-statement-id');
        return $(line).find('.details').html(this._clearButtonTemplate(bankStatementId, letter));
      });

      return this._notReconciliatedLines().each(function() {
        return $(this).find('.details').html("<div class='letter'></div>");
      });
    }

    _clearButtonTemplate(bankStatementId, letter) {
      const removeLabel = I18n.t("front-end.bank_reconciliation.remove");
      return `<div class='letter'>${letter}</div> \
<a href='/backend/bank-reconciliation/letters/${bankStatementId}?letter=${letter}' data-remote='true' rel='nofollow' data-method='delete' id='clear'> \
<i></i> \
<span>${removeLabel}</span> \
</a>`;
    }

    _showOrHideCompleteButtons() {
      return this._showAndHideLinkForCollection('complete',
        $("[data-type=journal_entry_item].selected .details a"),
        $("[data-type=journal_entry_item]:not(.selected) .details a"));
    }

    _showAndHideLinkForCollection(linkType, toShow, toHide) {
      toShow.each(function() {
        $(this).attr('id', linkType);
        return $(this).find('span').html($(this).data(`name-${linkType}`));
      });
      return toHide.each(function() {
        if ($(this).attr('id') === linkType) {
          $(this).find('span').html('');
          return $(this).attr('id', '');
        }
      });
    }

    _setButtonActiveState($button, enabled) {
      if ($button.hasClass('btn')) {
        $button.attr("disabled", !enabled);
        return $button.parents('.btn-group').attr("disabled", !enabled);
      } else {
        return $button.parents('.btn-group').find('> button').attr("disabled", !enabled);
      }
    }

    _showOrHideNewPaymentButtons() {
      const selectedBankStatements = this._bankStatementLines().filter(".selected");
      const selectedJournalItems = this._journalEntryLines().filter(".selected");
      if (selectedBankStatements.length > 0) {
        this._updateIdsInButtons();
        this._setButtonActiveState($("a.from-selected-bank"), true);
      } else {
        this._setButtonActiveState($("a.from-selected-bank"), false);
      }

      if (selectedJournalItems.length > 0) {
        this._updateIdsInButtons();
        this._setButtonActiveState($("a.from-selected-journal"), true);
      } else {
        this._setButtonActiveState($("a.from-selected-journal"), false);
      }

      if ((selectedBankStatements.length === 0) || (selectedJournalItems.length === 0)) {
        return this._setButtonActiveState($("a.gap-creation"), false);
      } else {
        return this._setButtonActiveState($("a.gap-creation"), true);
      }
    }

    _showOrHideReconciliatedLines() {
      if ($("#hide-lettered").is(":checked")) {
        return this._reconciliatedLines().hide();
      } else {
        return this._reconciliatedLines().show();
      }
    }

    _updateIdsInButtons() {
      this._updateItemIdsInButtons();
      return this._updateEntryIdsInButtons();
    }

    _updateItemIdsInButtons() {
      return this._updateIdsInButtonsFor('.from-selected-bank, .gap-creation', 'bank_statement_item');
    }

    _updateEntryIdsInButtons() {
      return this._updateIdsInButtonsFor('.from-selected-journal, .gap-creation', 'journal_entry_item');
    }

    _updateIdsInButtonsFor(selector, type) {
      const selectedLines = this._lines().filter(`[data-type=${type}].selected`);
      const ids = selectedLines.get().map(line => {
        return this._idForLine(line);
      });
      const with_questionmark = new RegExp(".*/\\w+(\\?).*?");
      const id_space = new RegExp(`(.(?!/)*/\\w+\\?.*?)(&?${type}_ids\\[\\]=.*)+(&.*)?`);
      return $(selector).each(function(i, button) {
        let url = $(button).attr('href');
        if (with_questionmark.exec(url)) {
          if (!id_space.exec(url)) { url = url + `&${type}_ids[]=PLACEHOLDER`; }
        } else {
          if (!id_space.exec(url)) { url = url + `?${type}_ids[]=PLACEHOLDER`; }
        }
        url = url.replace(id_space, `$1&${type}_ids[]=${ids.join(`&${type}_ids[]=`)}$3`);
        return $(button).attr('href', url);
      });
    }

    // AJAX CALLS

    _letterItems(lines) {
      const journalLines = lines.filter(":not(.lettered)[data-type=journal_entry_item]");
      const journalIds = journalLines.get().map(line => {
        return this._idForLine(line);
      });
      const bankLines = lines.filter(":not(.lettered)[data-type=bank_statement_item]");
      const bankIds = bankLines.get().map(line => {
        return this._idForLine(line);
      });
      const url = '/backend/bank-reconciliation/letters';
      return $.ajax(url, {
        type: 'POST',
        dataType: 'JSON',
        data: {
          cash_id: $('#cash_id').val(),
          journal_entry_items: journalIds,
          bank_statement_items: bankIds
        },
        success: response => {
          lines.find(".details .letter").text(response.letter);
          lines.removeClass("selected");
          lines.addClass("lettered");
          $(lines).find(".debit, .credit").trigger("change");
          this.uiUpdate();
          return true;
        },
        error(data) {
          alert('Error while lettering the lines.');
          console.log(data);
          return false;
        }
      }
      );
    }

    _unletterItems(letter) {
      return $.ajax({
        url: '/backend/bank-reconciliation/letters/',
        type: 'DELETE',
        dataType: 'JSON',
        data: {
          cash_id: $('#cash_id').val(),
          letter
        },
        success: response => {
          const lines = this._linesWithReconciliationLetter(response.letter);
          lines.find(".details .letter").text("");
          lines.removeClass("lettered");
          $(lines).find(".debit, .credit").trigger("change");
          this.uiUpdate();
          return true;
        },
        error(data) {
          alert('Error while unlettering the lines.');
          console.log(data);
          return false;
        }
      });
    }

    _deleteLine(line) {
      const url = '/backend/bank-statement-items/' + line.data('id');
      return $.ajax(url, {
        type: 'DELETE',
        dataType: 'JSON',
        success: response => {
          this._destroyBankStatementItem($(`.reconciliation-item[data-id=${response.id}]`));
          return true;
        },
        error(data) {
          alert('Error while deleting the line.');
          console.log(data);
          return false;
        }
      }
      );
    }

    // HELPER METHODS

    _lines() {
      return $(".reconciliation-item");
    }

    _bankStatementLines() {
      return $(".reconciliation-item[data-type=bank_statement_item]");
    }

    _journalEntryLines() {
      return $(".reconciliation-item[data-type=journal_entry_item]");
    }

    _filterLinesBy(lines, filters) {
      const {date, debit, credit} = filters;
      return lines.filter((i, e) => {
        if (this._dateForLine($(e)) !== date) { return; }
        return (this._debitForLine($(e)) === debit) && (this._creditForLine($(e)) === credit);
      });
    }

    _dateForLine(line) {
      return line.prevAll(".date-header:first").find('p').text();
    }

    _creditForLine(line) {
      const creditElement = line.find(".credit");
      return this._floatValueForTextOrInput(creditElement);
    }

    _debitForLine(line) {
      const debitElement = line.find(".debit");
      return this._floatValueForTextOrInput(debitElement);
    }

    _floatValueForTextOrInput(element) {
      const value = element.is("input") ? element.val() : element.text();
      return parseFloat(value || 0);
    }

    _idForLine(line) {
      return parseInt($(line).data('id'));
    }
  };

})(ekylibre, jQuery);
