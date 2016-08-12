$(function () {
  max_file_size = 2147483648;
  max_file_size_str = "2GB";
  max_total_file_size = 4294967296;
  max_total_file_size_str = "4GB";
  $('#fileupload').fileupload(
      'option',
      'acceptFileTypes',
      /(\.|\/)(ods|odf|xlsx?|pdf|pptx?|tex|dvi|odt|rtf|docx?|txt|tiff?|gif|jpe?g|png|zip|gz|tar|7z|bz2?)$/i
  );
});
