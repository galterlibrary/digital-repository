(function($) {
    function initOpenSeadragon() {
      $('picture[data-openseadragon]').openseadragon();
      $(document).off('shown.bs.modal');
    }

    $(document).on('shown.bs.modal', initOpenSeadragon);
    //$(document).on('page:load', initOpenSeadragon);
    //$(document).ready(initOpenSeadragon);
})(jQuery);
