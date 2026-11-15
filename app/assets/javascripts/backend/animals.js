//= require bootstrap/modal

(function(E, G, $) {
  $(document).ajaxSend(function(e, xhr, options) {
    const token = $('meta[name=\'csrf-token\']').attr('content');
    xhr.setRequestHeader('X-CSRF-Token', token);
  });


  class golumn {
    constructor(id) {
      this.id = id;

      this.selectedItemsIndex = {};

      this.groups = ko.observableArray([]);
      this.containers = ko.observableArray([]);
      this.animals = ko.observableArray([]);

      this.counter = ko.observable(0);

      this.keeper_id = undefined;


      this.enableDropZones = state => {
        if (state == null) { state = false; }
        return ko.utils.arrayForEach(this.groups(), group => {
          group.droppable(state);
          return ko.utils.arrayForEach(group.containers(), container => {
            if (!container.protect) { return container.droppable(state); }
          });
        });
      };

      this.moveAnimals = (container, group) => {

        const params = {};
        if (container !== undefined) { params['new_container'] = container.id(); }
        params['parameters'] = true;

        // find if any group changed
        for (id in this.selectedItemsIndex) {
          var item = this.selectedItemsIndex[id];
          if ((item.parent.parent.id !== group.id) && (group !== undefined)) {
            params['new_group'] = group.id;
          }
        }

        return E.dialog.open(this.rebuildUrl(params), {
          returns: {
            success: (frame, data, status, request) => {
              Turbolinks.visit('#', {action: 'replace'});

              frame.dialog("close");
            },

            invalid(frame, data, status, request) {
              frame.html(request.responseText);
            }
          }
        }
        );
      };

      // by default, build url to move animals
      this.rebuildUrl = function() {

        let options = Array.from(arguments).shift();

        let base_url = options['base_url'] || $('a[data-target=animal_group_changing]').attr('href');
        const parameters = options['parameters'] || false;

        options = Array.from(arguments).shift();
        if (!options['reference_name']) { options['reference_name'] = 'animal'; }
        if (Object.keys(this.selectedItemsIndex).length && this.keeper_id) { options['keeper_id'] = this.keeper_id; }

        delete options['parameters'];

        if (parameters) { base_url += `&${$.param(options)}`; }

        return base_url;
      }.bind(this);

      this.impactOnSelection = () => {

        this.counter(Object.keys(this.selectedItemsIndex).length);

        $.post($('*[data-keep-animals-path]').first().data('keep-animals-path'), {id: Object.keys(this.selectedItemsIndex).join(',')} , data => {
          if ((data.id != null) && data.id) { return this.keeper_id = data.id; }
        });

        return $.get($('*[data-matching-interventions-path]').first().data('matching-interventions-path'), {id: Object.keys(this.selectedItemsIndex).join(',')});
      };


      this.resetSelectedItems = () => {
        for (id  in this.selectedItemsIndex) {
          var item = this.selectedItemsIndex[id];
          item.checked(false);
        }


        $.post($('*[data-keep-animals-path]').first().data('keep-animals-path'), {id: []}, data => {
          if (data.id != null) { return this.keeper_id = undefined; }
        });


        return this.selectedItemsIndex = {};
      };
    }
  }


  this.loadData = (golumn, scope, element) => {
    $.ajax('/backend/animals/load_animals', {
      type: 'GET',
      dataType: 'JSON',
      data: {
        golumn_id: golumn,
        scope
      },
      beforeSend() {
        element.addClass("loading");
      },
      complete() {
        element.removeClass("loading");
      },
      success(json_data) {
        const groups = ko.utils.arrayMap(json_data.groups, jGroup => {

          const group = new G.Group(jGroup.id, jGroup.name, jGroup.edit_path, []);

          group.containers(ko.utils.arrayMap(jGroup.places, jPlace => {

            const container = new G.Container(jPlace.id, jPlace.name, [], group);

            container.items(ko.utils.arrayMap(jPlace.animals, animal => {
              return new G.Item(animal.id, animal.name, animal.status, animal.sex, animal.show_path, container);
            })
            );

            return container;
          })
          );

          //items without place:
          if (jGroup.without_place) {
            const new_container = new G.Container(jGroup.without_place.id, jGroup.without_place.name, [], group);
            new_container.items(ko.utils.arrayMap(jGroup.without_place.animals, animal => {
              return new G.Item(animal.id, animal.name, animal.status, animal.sex, animal.show_path, new_container);
            })
            );

            group.containers.push(new_container);
          }

          return group;
        });

        if (json_data.without_group) {
          const new_group = new G.Group(json_data.without_group.id, json_data.without_group.name, json_data.without_group.edit_path, []);

          //items without place:
          if (json_data.without_group.without_place) {
            const new_container = new G.Container(json_data.without_group.without_place.id, json_data.without_group.without_place.name, [], new_group);
            new_container.items(ko.utils.arrayMap(json_data.without_group.without_place.animals, animal => {
              return new G.Item(animal.id, animal.name, animal.status, animal.sex, animal.show_path, new_container);
            })
            );

            new_group.containers.push(new_container);

            groups.push(new_group);
          }
        }

        window.app.groups = ko.observableArray(groups);

        ko.applyBindings(window.app);

        return true;
      },

      error(data) {
        return false;
      }
    }
    );

  };

  $(document).on('click', 'a[data-toggle=dialog]', e => {

    const dropdown = $(e.currentTarget).closest('.dropdown-menu').siblings('.dropdown-toggle');

    if (dropdown != null) {
      dropdown.dropdown('toggle');
    }

    E.dialog.open(app.rebuildUrl({base_url: e.currentTarget.getAttribute('href'), parameters: $(e.currentTarget).data('parameters'), reference_name: $(e.currentTarget).data('reference-name')}), {
      returns: {
        success(frame, data, status, request) {

          frame.dialog("close");

          if ($(e.currentTarget).data('refresh')) {
            window.onLoad();
          }

        },

        invalid(frame, data, status, request) {
          frame.html(request.responseText);
        }
      }
    }
    );

    window.app.resetSelectedItems();

    return false;
  });

  this.onLoad = () => $("*[data-golumns='animal']").each(function() {
    const golumn_id = $(this).data("golumns");
    ko.unapplyBindings($(document.body));

    const scope = $('[data-scoped-items].active').data('scoped-items');
    window.app = new golumn(golumn_id);
    return window.loadData(golumn_id, scope, $(this));
  });

  $(document).on('click', '[data-scoped-items]', e => {
    const scope = $(e.currentTarget).data('scoped-items');

    $(e.currentTarget).data('scope', true);
    $('[data-toggle=item-scope]').removeClass('active');
    $(e.currentTarget).addClass('active');

    window.onLoad();
    return e.preventDefault();
  });


  $(document).ready(function() {
    // $("*[data-golumns]").mousewheel (event, delta) ->
    //   if $(this).prop("wheelable") != "false"
    //     @scrollLeft -= (delta * 30)
    //     event.preventDefault()

    window.onLoad();
    return $('.golumn-columns').scroll(() => {
      return $('.golumn-items-counter').css('right', - $('.golumn-columns').scrollLeft() );
    });
  });


  ko.unapplyBindings = ($node, remove) => {
    $node.find('*').each(function() {
      return $(this).unbind();
    });

    if (remove) {
      return ko.removeNode($node[0]);
    } else {
      return ko.cleanNode($node[0]);
    }
  };

  return E.onElementDetected('animals-interventions-menu', e => {
    const $listBtn = $('[data-janus-href="list"]');
    const $targetBtns = $('[data-hide-on-list]');

    if ($listBtn.hasClass('active')) {
      return $targetBtns.hide();
    }
});

})(ekylibre, golumn, jQuery);
