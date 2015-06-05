Blacklight.onLoad(function() {
  function get_autocomplete_opts(field) {
    var autocomplete_opts = {
      minLength: 2,
      source: function( request, response ) {
        $.getJSON( "/authorities/generic_files/" + field, {
          q: request.term
        }, response );
      },
      focus: function() {
        // prevent value inserted on focus
        return false;
      },
      complete: function(event) {
        $('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
      }
    };
    return autocomplete_opts;
  }

    // there are two levels of vocabulary auto complete.
    // currently we have this externally hosted vocabulary
    // for geonames.  I'm not going to make these any easier
    // to implement for an external url (it's all hard coded)
    // because I'm guessing we'll get away from the hard coding
  var cities_autocomplete_opts = {
    source: function( request, response ) {
      $.ajax( {
        url: "http://ws.geonames.org/searchJSON",
        dataType: "jsonp",
        data: {
          featureClass: "P",
          style: "full",
          maxRows: 12,
          name_startsWith: request.term
        },
        success: function( data ) {
          response( $.map( data.geonames, function( item ) {
            return {
              label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
              value: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName
            };
          }));
        },
      });
    },
    minLength: 2
  };
  $("#generic_file_based_near").autocomplete(get_autocomplete_opts("location"));

  var autocomplete_vocab = new Object();

  // the url variable to pass to determine the vocab to attach to
  autocomplete_vocab.url_var = ['subject', 'language', 'creator', 'contributor'];
  // the form name to attach the event for autocomplete
  autocomplete_vocab.field_name = new Array();

  // loop over the autocomplete fields and attach the
  // events for autocomplete and create other array values for autocomplete
  for (var i=0; i < autocomplete_vocab.url_var.length; i++) {
    autocomplete_vocab.field_name.push(
        'generic_file_' + autocomplete_vocab.url_var[i]);
    // autocompletes
    $("input." + autocomplete_vocab.field_name[i]).each(function(index) {
        var $this = $(this);
        // Additional fields in multi-field groups are missing ids
        // on page load, this screws with autocomplete and is corrected here
        if (!$this.attr('id')) {
            $this.attr('id', autocomplete_vocab.field_name[i] + index);
        }
        enable_autocomplete($this, autocomplete_vocab.url_var[i])
    });
  }

  // Fix clone's id so it's not duped with origin
  function fix_clone_id(clone) {
      if (/\d/.test(clone.attr('id'))) {
          clone.attr(
              'id', clone.attr('id').replace(/\d+$/, function(n){ return ++n })
          );
      } else {
          clone.attr('id', clone.attr('id') + '1')
      }
  }

  // Attach autocomplete after adding a field
  function setup_autocomplete(e, cloneElem) {
      var $cloneElem = $(cloneElem);
      var clean_id = $cloneElem.attr('id').replace(/\d+$/g, '');
      fix_clone_id($cloneElem);
      if ((index = $.inArray(clean_id, autocomplete_vocab.field_name)) != -1) {
          if (clean_id == 'generic_file_based_near') {
              $cloneElem.autocomplete(cities_autocomplete_opts);
          } else {
              enable_autocomplete($cloneElem, autocomplete_vocab.url_var[index])
          }
      }
  }

  function enable_autocomplete(element, url) {
      element.bind( "keydown", function( event ) {
          if ( event.keyCode === $.ui.keyCode.TAB &&
                  $( this ).data( "autocomplete" ).menu.active ) {
              event.preventDefault();
          }
      }).autocomplete(get_autocomplete_opts(url));
  }

  $('.multi_value.form-group').manage_fields({add: setup_autocomplete});
});
