//= require jquery/iframe-transport
//= require jquery/fileupload

(function($) {

  "use strict";

  $.widget("ui.attachmentController", {
    options: {
      fullWidget: false,
      fullWidgetClass: 'expanded'
    },

    _create() {
      $.extend(true, this.options, this.element.data("attachment-controller"));

      const widget = this;
      this.element = $(this.element);
      this.root = this.element.closest('.attachments');

      this.element.fileupload({
        url: this.element.data('attach'),
        dataType: 'json',
        dropZone: '.attachment-files',
        add: (e, data) => {
          const $el = $(`<div class="file">\
<div class="file-body">\
<div class="file-actions"><a href="" data-attachment-destroy="true" disabled><i></i></a></div>\
<div class="file-name">`+data.files[0].name+`</div>\
</div>\
</div>`);

          data.context = $el.appendTo(this.root.find('.attachment-files'));

          this._refreshPlaceholder();

          // send request
          data.submit();
          return true;
        },

        submit: (e, data) => {
          data.formData = {
            'attachments[document_attributes][name]': data.files[0].name,
            'attachments[document_attributes][key]': `${new Date().getTime()}-${data.files[0].name}`,
            'attachments[document_attributes][uploaded]': true
          };

          const file = data.context.closest('.file');
          file.addClass('loading');
          this.root.find('.file-progress-bar .file-progress').css({width: '0%'});
          this.root.find('.file-progress-bar').slideDown();
          return true;
        },

        progressall: (e, data) => {
          const progress = parseInt((data.loaded / data.total) * 100, 10);
          // @root.find('.attachment-files-bitrate').text((data.bitrate / 1024).toFixed(2) + 'Kb/s')
          return this.root.find('.file-progress-bar .file-progress').css({width: `${progress}%`});
        },

        done(e, data) {
          const file = $(data.context).closest('.file');
          const {
            result
          } = data;
          file.attr('data-attachment-preview', result.path);
          file.find('.file-name').html(result.name);
          file.removeClass('loading').removeClass('failed');

          file.find('.file-body').css("background-image", `url('${result.document.thumbnail_path}')`);

          const indicator = file.find('*[data-attachment-destroy]');
          indicator.data('href', result.path);
          return indicator.removeAttr('disabled');
        },

        fail(e, data) {
          const file = $(data.context).closest('.file');
          file.removeClass('loading').addClass('failed');
          const indicator = file.find('*[data-attachment-destroy]');
          return indicator.attr('title', data.errorThrown);
        },

        always: () => {
          // @root.find('.attachment-files-bitrate').text('')
          return this.root.find('.file-progress-bar').slideUp();
        }
      });

      $(document).on('click', '*[data-attachment-destroy]', function(e) {
        e.preventDefault();
        const url = $(this).attr('href');
        if (url) {
          $.ajax({
            url,
            method: 'post',
            data: {"_method": "delete"},
            success: data => {
              $(e.currentTarget).closest('.file').remove();
              return widget._refreshPlaceholder();
            },
            error: data => {
              $(e.currentTarget).closest('.file').addClass('failed');
              return console.log('Unable to delete file');
            }
          });
        } else {
          $(e.currentTarget).closest('.file').remove();
          widget._refreshPlaceholder();
        }

        return false;
      });

      $(document).on('click', '*[data-attachment-preview] .file-name, *[data-attachment-preview] .file-body', function(e) {
        e.preventDefault();
        const url = $(this).closest('*[data-attachment-preview]').data('attachment-preview');
        $.ajax({
          url,
          method: 'GET',
          success(data) {
            const $el = $(`<iframe src='${data.document.file_path}'/>`);
            const $modal = $('*[data-attachment-thumblink-target]');
            $modal.find('.modal-title').html(data.name);
            $modal.find('.modal-body').html($el);
            return $modal.modal('show');
          },
          error(data) {
            return console.log('Unable to load file');
          }
        });
        return false;
      });

      $(document).on('click','*[data-attachments-expand]', function(e) {
        e.preventDefault();
        return widget.toggleWidget();
      });

      $(document).bind('dragover', function(e) {
        const dropZone = $('.attachment-files');
        const timeout = window.dropZoneTimeout;
        if (!timeout) {
          dropZone.addClass('in');
        } else {
          clearTimeout(timeout);
        }
        let found = false;
        let node = e.target;
        while (true) {
          if (node === dropZone[0]) {
            found = true;
            break;
          }
          node = node.parentNode;
          if (node === null) {
            break;
          }
        }
        if (found) {
          dropZone.addClass('hover');
        } else {
          dropZone.removeClass('hover');
        }
        window.dropZoneTimeout = setTimeout((function() {
          window.dropZoneTimeout = null;
          dropZone.removeClass('in hover');
        }), 100);
      });

      return this._refreshPlaceholder();
    },

    _refreshPlaceholder() {
      if (this.root.find('.attachment-files').find('.file').length > 0) {
        this.root.find('.attachment-files-placeholder').hide();
        return this.root.find('*[data-attachments-expand]').show();
      } else {
        this.root.find('.attachment-files-placeholder').show();
        return this.root.find('*[data-attachments-expand]').hide();
      }
    },


    toggleWidget() {
      this.options.fullWidget = !this.options.fullWidget;
      if (this.options.fullWidget) {
        return $('.attachments').addClass(this.options.fullWidgetClass);
      } else {
        return $('.attachments').removeClass(this.options.fullWidgetClass);
      }
    }
  }
  );

  return $(document).ready(() => $("*[data-attach]").each(function() {
    return $(this).attachmentController();}));

})(jQuery);
