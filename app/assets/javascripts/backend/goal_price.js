(function($) {
  "use strict";

  $(document).on("slided", "*[data-regulator]", function() {
    let item, price, quantity, revenue;
    const element = $(this);
    const cell = element.closest("*[data-beehive-cell]");

    let expenses = 0;
    cell.find("*[data-fake-price]").each(function() {
      const item = $(this);
      return expenses += item.data("fake-expense-coeff") * cell.find(`#${item.data('fake-price')}`).slider("value");
    });

    cell.find(".slider-salary").each(function() {
      return expenses += $(this).slider("value") * 12 * 1.43;
    });

    cell.find(".slider-provision").each(function() {
      return expenses += $(this).slider("value");
    });
    console.log(`Expenses: ${expenses}`);

    if (element.hasClass("slider-yield")) {
      let other_revenues = 0;
      cell.find("*[data-fake-price]").each(function() {
        const item = $(this);
        if (item.data("fake-price") !== element.attr("id")) {
          return other_revenues += item.data("fake-revenue");
        }
      });
      console.log(`Other revenues: ${other_revenues}`);

      // Compute quantity in tons
      item = cell.find(`*[data-fake-price='${element.attr('id')}']`);
      console.log(`Revenue: ${other_revenues + item.data('fake-revenue')}`);
      quantity = element.slider("value") * item.data("fake-work-quantity") * 0.1;
      console.log(quantity);
      revenue = expenses - other_revenues;
      price = revenue / quantity;
      item.html(`${Math.round(price)}€/t`);
      item.attr("data-fake-revenue", revenue);
      item.data("fake-revenue", revenue);
    } else {
      let total = 0;
      cell.find("*[data-fake-price]").each(function() {
        return total += $(this).data("fake-work-quantity");
      });
      cell.find("*[data-fake-price]").each(function() {
        item = $(this);
        // Compute quantity in tons
        quantity = cell.find(`#${item.data('fake-price')}`).slider("value") * item.data("fake-work-quantity") * 0.1;
        console.log(quantity);
        revenue = (expenses * item.data("fake-work-quantity")) / total;
        price = revenue / quantity;
        item.html(`${Math.round(price)}€/t`);
        return item.data("fake-revenue", revenue);
      });
    }

    return true;
  });

  return true;
})(jQuery);
