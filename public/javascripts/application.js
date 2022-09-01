$(() => {
  removeFlashMessage(3000);
  $("div.wishlist-item-container-right img").on("click", onDeleteItem);
  $("form.wishlist-search-form").on("submit", onWishListSearch);
  $("section.found-users").on("click", onUserLinkClick);
});
