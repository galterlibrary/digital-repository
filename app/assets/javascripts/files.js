$(function () {
  $('#fileupload').fileupload(
      'option',
      'acceptFileTypes',
      /(\.|\/)(cvs|tsv|ods|xlsx?|pdf|pptx?|tex|dvi|odf|rtf|docx?|txt|tiff?|gif|jpe?g|png)$/i
  );
});
