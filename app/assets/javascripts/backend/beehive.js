//= require jquery.blank
//= require jquery-ui/widgets/sortable

(function($) {
  "use strict";

  $.beehive = {
    save(beehive) {
      const boxes = beehive
        .find("*[data-beehive-box]")
        .map(function() {
          return {
            cells: $(this).find("*[data-beehive-cell]").map( function() {
              return $(this).data("beehive-cell");
            }).get()
          };
        }).get();
      return $.ajax({
        url: beehive.data("beehive-save-url"),
        type: 'patch',
        data: {
          boxes
        },
        error(request, status, error) {
          return console.error(`Cannot save beehive: ${status} ${error}`, request);
        }
      });
    },

    reset(beehive) {
      return $.ajax({
        url: beehive.data("beehive-reset-url"),
        type: 'post',
        success(data, status, request) {
          return Turbolinks.visit();
        }
      });
    },

    setSortable(beehive) {
      $.beehive.addCellProposers(beehive);
      return beehive.find("*[data-beehive-box]")
        .sortable({
          connectWith: "div[data-beehive-box]",
          handle: ".cell-title",
          tolerance: "pointer",
          placeholder: "cell cell-placeholder",
          items: "> *[data-beehive-cell]",
          dropOnEmpty: true,
          update() {
            $(window).trigger('resize');
            return $.beehive.save(beehive);
          }}).disableSelection();
    },

    addBox(beehive) {
      const button = beehive.find("*[data-beehive-task='new-box']");
      const box = $("<div>")
        .addClass("box box-horizontal")
        .attr("data-beehive-box", "horizontal")
        .insertBefore(button);
      return $.beehive.setSortable(beehive);
    },

    addCell(beehive) {
      const select = beehive.find("select[name='cell']");
      const name = select.val();
      // console.log "Adding #{name} cell..."
      $.beehive.addCellProposers(beehive);
      const box = beehive.find("*[data-beehive-box]").first();
      return $.ajax({
        url: `/backend/cells/${name}_cell`,
        data: {
          beehive: beehive.data("beehive"),
          type: name,
          layout: true
        },
        dataType: "html",
        success(data, status, request) {
          // console.log "Success..."
          const cell = $(data);
          cell.appendTo(box);
          cell.trigger('cell:load');
          $(window).trigger('resize');
          return $.beehive.save(beehive);
        },
        error(request, status, error) {
          console.error(`Error while retrieving full cell ${name}: ${error}`, request);
          return beehive.trigger('cell:error');
        }
      });
    },

    addCellProposers(beehive) {
      if (beehive.find("*[data-beehive-box]").length <= 0) {
        return $.beehive.addBox(beehive);
      }
    }
  };

  $(document).on("click", "a[href][data-beehive-task='configure']", function() {
    const element = $(this);
    const beehive = $(element.attr("href"));
    if (beehive.hasClass("configuring")) {
      beehive.removeClass("configuring");
      beehive.find("*[data-beehive-box]").sortable("destroy");
      element.removeClass("active");
      $(window).trigger('resize');
    } else {
      beehive.addClass("configuring");
      element.addClass("active");
      $.beehive.setSortable(beehive);
    }
    return false;
  });

  $(document).on("click", "a[href][data-beehive-task='fullscreen']", function() {
    const element = $(this);
    const beehive = $(element.attr("href"))[0];
    if (beehive.requestFullscreen) {
      beehive.requestFullscreen();
    } else if (beehive.requestFullScreen) {
      beehive.requestFullScreen();
    } else if (beehive.msRequestFullscreen != null) {
      beehive.msRequestFullscreen();
    } else if (beehive.mozRequestFullScreen != null) {
      beehive.mozRequestFullScreen();
    } else if (beehive.webkitRequestFullscreen != null) {
      beehive.webkitRequestFullscreen();
    } else {
      console.warn("Cannot request fullscreen");
    }
    return false;
  });

  $(document).on("click", "a[href][data-beehive-task='new-box']", function() {
    // console.log "New box..."
    const element = $(this);
    $.beehive.addBox($(element.attr("href")));
    return false;
  });

  $(document).on("click", "a[href][data-beehive-task='new-cell']", function() {
    // console.log "New cell..."
    const element = $(this);
    $.beehive.addCell($(element.attr("href")));
    return false;
  });

  $(document).on("click", "a[href][data-beehive-task='reset']", function() {
    // console.log "Reset config..."
    const element = $(this);
    $.beehive.reset($(element.attr("href")));
    return false;
  });

  $(document).on("click", "*[data-beehive-cell] a[href][data-beehive-remove='cell']", function() {
    const element = $(this);
    const beehive = $(element.attr("href"));
    const cell = element.closest("*[data-beehive-cell]");
    cell.remove();
    $(window).trigger('resize');
    $.beehive.save(beehive);
    return false;
  });

  $.fn.raiseContentErrorToCellTitle = function() {
    const cells = $(this);
    return cells.each(function() {
      const cell = $(this);
      if (cell.find('.cell-content .error').length > 0) {
        return cell.closest('.beehive')
          .find('.cell-title[href="#' + cell.attr('id') + '"]')
          .closest('li')
          .addClass('error');
      }
    });
  };

  $(document).on('turbolinks:load', '.beehive .cell', $.fn.raiseContentErrorToCellTitle);

  $(document).ready(() => // Adds error style on title if necessary
  $(".beehive .cell").raiseContentErrorToCellTitle());
  return true;
})(jQuery);
