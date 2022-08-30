$(() => {
  $("div.wishlist-item-container img").on("click", e => {
    const button_id = e.target.id;
    const item_id = button_id.split("--")[1];
    const request = $.ajax({
      method: "delete",
      url: `/wishlist/${item_id}`,
    });
    request.done((data, status, jqXHR) => {
      $(`div#${item_id}`).fadeOut();
    });
  });
});
