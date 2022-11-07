const onDeleteItem = e => {
  const button_id = e.target.id;
  const item_id = button_id.split("__")[1];
  console.log(button_id, item_id);
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
          `<li class='user-wishlist-bullet action-btn'><a id='userquery___${element.user_id}'>${element.email}</a></li>`
        );
      });
    }
  });
};

const onUserLinkClick = e => {
  if (e.target.tagName === "A") {
    const userSection = $("section.found-users");
    userSection.empty();
    const userId = e.target.id.split("___")[1];

    const request = $.ajax({
      method: "get",
      url: `/wishlists/user/${userId}`,
    });
    request.done(data => {
      if (Object.values(data).length === 0) {
        userSection.append("<p>No Items in this User's Wishlist</p>");
      }
      Object.values(data).forEach(el => {
        userSection.append(`<article class='wishlist-item-container'>
      <div class='wishlist-item-container-left'> 
        <h2><a href="${el.original_url}" target="_blank" rel="noopener noreferrer">${el.title}</a></h2>
        <p>${el.description}</p>
      </div>
      <div class='wishlist-item-container-right'>
        <p class='item_price'>${el.price}</p>
        <img class='item_img' src="${el.image_url}">
        <a href='/wishlist/${el.belongs_to}/${el.item_id}'>More Details</a>   
      </div>
    </article>`);
      });
    });
  }
};

const createFlashMessage = (msg, msgType = "message") => {
  $("header").append(`<p class='flash ${msgType}'>${msg}</p>`);
  setTimeout(function () {
    $("p.flash").slideUp();
  }, 3000);
};

const onClaimFormSubmit = e => {
  e.preventDefault();
  const [current_user_id, list_item_user_id, item_id] =
    e.target.elements[0].value.split("--");
  console.log(current_user_id, list_item_user_id, item_id);
  if (!current_user_id) {
    createFlashMessage(
      "Please sign in to claim other users' wishlist items.",
      "error"
    );
    return;
  }
  if (current_user_id === list_item_user_id) {
    createFlashMessage("You cannot claim your own wishlist items.", "error");
    return;
  }
  const payload = {
    current_user_id,
    list_item_user_id,
    item_id,
  };
  const request = $.ajax({
    method: "post",
    url: `/wishlist/claim-item`,
    data: payload,
  });
  request.done((data, textStatus, xhr) => {
    if (xhr.status === 201) {
      $("form.claim-form").remove();
      $("div.claim-container")
        .append(`<img class='claimed-img' src='/images/accept.png' />
    <span>Claimed</span>`);
    }
  });
};
