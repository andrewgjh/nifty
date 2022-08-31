$(() => {
  $("p.flash").delay(3000).slideUp();
  $("div.wishlist-item-container img").on("click", onDeleteItem);
});
