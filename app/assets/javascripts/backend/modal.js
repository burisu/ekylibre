// This module permits to execute actions on modal

(function(E, $) {
  'use strict';

  class Modal {

    constructor(selector) {
      this.selector = selector;
      this.modal = $(selector);
      this.modalHeader = this.modal.find('.modal-header');
      this.modalBody = this.modal.find('.modal-body');
      this.modalFooter = this.modal.find('.modal-footer');
    }

    resetModal() {
      this.modalHeader.find('> *:not(".close")').remove();
      this.modalBody.empty();
      return this.modalFooter.empty();
    }

    removeModalContent() {
      return this.getModalContent().empty();
    }

    getModal() {
      console.warn("Modal#getModal is deprecated, use getElement instead");
      return this.getElement();
    }

    getElement() {
      return this.modal;
    }

    getModalContent() {
      console.warn("Modal#getModalContent is deprecated, use getContent instead");
      return this.getContent();
    }

    getContent() {
      return this.modal.find(".modal-content");
    }

    setContent(content) {
      return Promise.resolve(content)
        .then(content => this.getContent().html(content));
    }

    getHeader() {
      return this.modalHeader;
    }

    getBody() {
      return this.modalBody;
    }

    getFooter() {
      return this.modalFooter;
    }

    show() {
      return this.modal.modal('show');
    }

    hide() {
      return this.modal.modal('hide');
    }

    close() {
      this.hide();
      return this.setContent('');
    }
  }

  E.modal = Modal;

  // Shortcut to open and set content of the modal
  // Returns a promise that resolves to the modal
  return E.modal.open = (selector, content) => {
    const modal = new Modal(selector);
    return modal.setContent(content)
      .then(() => modal.show())
      .then(() => modal).catch((e => Promise.reject({modal, error: e})));
  };

})(ekylibre, jQuery);
