$(function () {
  $('#fileupload').fileupload(
      'option',
      'acceptFileTypes',
      /(\.|\/)(pdf|pptx?|docx?|tiff?|txt|text|gif|jpe?g|png)$/i
  );
});
