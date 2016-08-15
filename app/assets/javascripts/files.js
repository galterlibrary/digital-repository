$(function () {
  max_file_size = 2147483648;
  max_file_size_str = "2GB";
  max_total_file_size = 4294967296;
  max_total_file_size_str = "4GB";

  $('#fileupload').fileupload(
      'option',
      'acceptFileTypes',
      /(\.|\/)(ods|odf|xlsx?|pdf|pptx?|tex|dvi|odt|rtf|docx?|txt|tiff?|gif|jpe?g|png|zip|gz|tar|7z|bz2?)$/i
  )

  function galterUploadAdded(e, data) {
    var total_sz = parseInt($('#total_upload_size').val()) + data.files[0].size;
    $('#total_upload_size').val( total_sz );
    if (data.files[0].error == 'acceptFileTypes'){
      $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click();
      $("#errmsg").html(
          "Sorry, we cannot currently accept files of type: " +
          data.files[0].name.split('.').pop()
      );
      $("#errmsg").fadeIn('slow');
    }
    // is file size too big
    else if (data.files[0].size > max_file_size) {
      $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click();
      $("#errmsg").html(data.files[0].name + " is too big. No files over " + max_file_size_str + " can be uploaded.");
      $("#errmsg").fadeIn('slow');
    }
    // cumulative upload file size is too big
    else if( total_sz > max_total_file_size) {
      if (first_file_after_max == '') first_file_after_max = data.files[0].name;
      $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click();
      // artificially bump size to max so small files don't sneak in out of order.
      $('#total_upload_size').val( max_total_file_size );
      $("#errmsg").html("All files selected from " + first_file_after_max + " and after will not be uploaded because your total upload is too big. You may not upload more than " + max_total_file_size_str + " in one upload.");
      $("#errmsg").fadeIn('slow');
    }
    else if( filestoupload > max_file_count) {
      if (first_file_after_max == '') first_file_after_max = data.files[0].name;
      $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click();
      $("#errmsg").html("All files selected from " + first_file_after_max + " and after will not be uploaded because your total number of files is too big. You may not upload more than " + max_file_count + " files in one upload.");
      $("#errmsg").fadeIn('slow');
    }
    else { $("#errmsg").fadeOut(); }
  }

  $('#fileupload').off("fileuploadadded");
  $('#fileupload').on("fileuploadadded", galterUploadAdded);
});
