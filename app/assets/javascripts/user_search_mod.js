$(function() {
  $('#new_user_name_skel').on("change", function (e) {
    set_perm_message();
  });

  $('#new_user_permission_skel').on('change', function() {
    set_perm_message();
  });

  $('#add_new_user_skel').on('click', function() {
    set_perm_message(true);
  });

  function set_perm_message(from_plus_botton) {
    if ($('.select2-chosen').text() == 'Search for a user' || from_plus_botton == true) {
      $('#new-user > p:first-child').html(
        'Enter User (one at a time)').css( 'color', 'black');
    } else if ($('#new_user_permission_skel').val() == 'none') {
      $('#new-user > p:first-child').html(
          'Please select permission level on the right').css(
            'color', 'red');
    } else {
      $('#new-user > p:first-child').html(
          "Don't forget to click the plus button on the right").css(
            'color', 'red');
    }
  }
});
