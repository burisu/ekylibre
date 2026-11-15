golumn.Container = class Container {
  constructor(id, name, items, parent) {
    this.name = name;
    this.parent = parent;
    this.id = ko.observable(id);
    this.toggleItems = ko.observable(false);
    this.items = ko.observableArray(items);
    this.count = ko.pureComputed(() => {
      return this.items().length;
    });
    this.hidden = ko.observable(false);
    this.toggle = () => {
      this.hidden(!this.hidden());
    };
    this.droppable = ko.observable(false);
    this.protect = false;

    this.toggleItems.subscribe(newValue => {

      return ko.utils.arrayForEach(this.items(), item => {
        return item.checked(newValue);
      });
    });
  }
};
