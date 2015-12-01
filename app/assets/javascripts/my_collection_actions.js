Blacklight.onLoad(function () {
  $('.add-col-to-col').on('click', function() {
    var forms = $('#collection-list-container form')
    var id = $(this).data('id');
    $('input[name="batch_document_ids[]"]').remove()
    $.each(forms, function(idx) {
      $(this).append('<input type="hidden" multiple="multiple" name="batch_document_ids[]" value="'+id+'" />');
    });
  });
});
