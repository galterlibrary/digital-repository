$(function() {
  if($(window).width() < 767) {
    $('.col-action-btn').addClass('btn-lg');
  }

  $('div').on('show.bs.collapse', function(event, child, data) {
    $("a[aria-controls='" + this.id + "']").html(
      '<span class="glyphicon glyphicon-collapse-up" aria-hidden="true"></span>'
    );
  });

  $('div').on('hide.bs.collapse', function(event, child, data) {
    $("a[aria-controls='" + this.id + "']").html(
      '<span class="glyphicon glyphicon-expand" aria-hidden="true"></span>'
    );
  });
})
