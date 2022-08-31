$(() => {
  $("p.flash").delay(3000).slideUp();
  $("div.wishlist-item-container-right img").on("click", onDeleteItem);
});
