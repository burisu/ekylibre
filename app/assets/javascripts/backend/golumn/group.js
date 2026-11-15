golumn.Group = class Group {
  constructor(id, name, edit_path, containers) {
    this.id = id;
    this.name = name;
    this.edit_path = edit_path;
    this.containers = ko.observableArray([]);
    this.toggleItems = ko.observable(false);
    this.droppable = ko.observable(false);

    this.count = ko.pureComputed(() => {
      let c = 0;
      ko.utils.arrayForEach(this.containers(), container => {
        return c += container.count();
      });
      return c;
    });

    this.toggleItems.subscribe(newValue => {

      return ko.utils.arrayForEach(this.containers(), container => {
        return container.toggleItems(newValue);
      });
    });
  }
};
