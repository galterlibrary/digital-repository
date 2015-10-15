Blacklight.onLoad(function () {
  $('.cat-cal-modal').on('click', function() {
    var forms = $('#catalogCollections form')
    var id = $(this).data('id');
    $('input[name="batch_document_ids[]"]').remove()
    $.each(forms, function(idx) {
      $(this).append('<input type="hidden" multiple="multiple" name="batch_document_ids[]" value="'+id+'" />');
    });
  });
});
