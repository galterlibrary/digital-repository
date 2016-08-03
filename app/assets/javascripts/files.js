$(function () {
  $('#fileupload').fileupload(
      'option',
      'acceptFileTypes',
      /(\.|\/)(csv|tsv|ods|odf|xlsx?|pdf|pptx?|tex|dvi|odt|rtf|docx?|txt|tiff?|gif|jpe?g|png|zip|gz|tar|7z|bz2?)$/i
  );
});
