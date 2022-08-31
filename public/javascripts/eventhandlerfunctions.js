const onDeleteItem = e => {
  const button_id = e.target.id;
  const item_id = button_id.split("--")[1];
  const request = $.ajax({
    method: "delete",
    url: `/wishlist/${item_id}`,
  });
  request.done((data, status, jqXHR) => {
    $(`div#${item_id}`).remove();
    $("header").append(
      "<p class='flash message'>The item has been deleted.</p>"
    );
    setTimeout(function () {
      $("p.flash").slideUp();
    }, 3000);
  });
};
