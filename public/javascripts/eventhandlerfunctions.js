const onDeleteItem = e => {
  const button_id = e.target.id;
  const item_id = button_id.split("--")[1];
  const request = $.ajax({
    method: "delete",
    url: `/wishlist/${item_id}`,
  });
  request.done(() => {
    $(`article#${item_id}`).remove();
    createFlashMessage("The item has been deleted.");
  });
};

const removeFlashMessage = ms => {
  $("p.flash").delay(ms).slideUp();
};

const onWishListSearch = e => {
  e.preventDefault();
  const userSection = $("section.found-users");
  userSection.empty();
  const searchEmail = e.target.elements.searchEmail.value;
  if (searchEmail.trim() === "") {
    createFlashMessage("Searches cannot be blank.");
    return;
  }
  const request = $.ajax({
    method: "get",
    url: `/wishlist/search?email=${searchEmail}`,
  });
  request.done(data => {
    if (data.length === 0) {
      userSection.append("<p class='center text'>No Users Found</p>");
    } else {
      userSection.append("<ul class='center users-list'></ul>");
      data.forEach(element => {
        $("ul.users-list").append(
          `<li class='user-wishlist-bullet action-btn'><a>${element}</a></li>`
        );
      });
    }
  });
};

const onUserLinkClick = e => {
  if (e.target.tagName === "A") {
    const userSection = $("section.found-users");
    userSection.empty();
    const email = e.target.innerHTML;
    const request = $.ajax({
      method: "get",
      url: `/wishlists/user/${email}`,
    });
    request.done(data => {
      Object.values(data).forEach(el => {
        userSection.append(`<article class='wishlist-item-container'>
      <div class='wishlist-item-container-left'> 
        <h2>${el.title}</h2>
        <p>${el.description}</p>
      </div>
      <div class='wishlist-item-container-right'>
        <p class='item_price'>${el.price}</p>
        <img class='item_img' src="${el.image_url}">
        <a href='/wishlist/<%= id %>'>More Details</a>   
      </div>
    </article>`);
      });
    });
  }
};

const createFlashMessage = msg => {
  $("header").append(`<p class='flash message'>${msg}</p>`);
  setTimeout(function () {
    $("p.flash").slideUp();
  }, 3000);
};
