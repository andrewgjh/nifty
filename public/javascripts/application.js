$(() => {
  removeFlashMessage(3000);
  $("div.wishlist-item-container-left img").on("click", onDeleteItem);
  $("form.wishlist-search-form").on("submit", onWishListSearch);
  $("section.found-users").on("click", onUserLinkClick);
  $("form.claim-form").on("submit", onClaimFormSubmit);
});
