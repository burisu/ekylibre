golumn.Item = class Item {
  constructor(id, name, status, sex, show_path, parent) {

    this.id = id;
    this.name = name;
    this.status = status;
    this.sex = sex;
    if (show_path == null) { show_path = ''; }
    this.show_path = show_path;
    this.parent = parent;
    this.sexClass = ko.pureComputed(() => {
      if (this.sex === 'male') { return "icon-mars"; } else if (this.sex === 'female') { return 'icon-venus'; } else { return ''; }
    });

    this.statusClass = ko.pureComputed(() => {
      return `status-${this.status}`;
    });

    this.stateClass = ko.pureComputed(() => {
      let klass = this.statusClass();
      if (this.checked()) {
        klass += ' active';
      }
      return klass;
    });

    this.flagClass = ko.pureComputed(() => {
      return `lights-${this.status}`;
    });

    this.checked = ko.observable(false);
    this.checked.subscribe(newValue => {
      if (newValue) {
        this.parent.protect = true;
        app.selectedItemsIndex[this.id] = this;
        return app.impactOnSelection();
      } else {
        this.parent.protect = false;
        delete app.selectedItemsIndex[this.id];
        return app.impactOnSelection();
      }
    });

  }
};