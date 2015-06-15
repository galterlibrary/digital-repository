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

  var autocomplete_vocab = new Object();

  // the url variable to pass to determine the vocab to attach to
  autocomplete_vocab.url_var = [
    'subject', 'language', 'creator', 'contributor', 'based_near'
  ];

  function clean_input_name(name) {
    return name.replace(/\[/, '_').replace(/[^a-z_]/g, '');
  }

  // loop over the autocomplete fields and attach the
  // events for autocomplete and create other array values for autocomplete
  for (var i=0; i < autocomplete_vocab.url_var.length; i++) {
    var vocab_type = autocomplete_vocab.url_var[i];

    $("input[name*='" + vocab_type + "']").each(function(index) {
        var $this = $(this);
        // Additional fields in multi-field groups are missing ids
        // on page load, this screws with autocomplete and is corrected here
        if (!$this.attr('id')) {
            $this.attr('id', clean_input_name($this.attr('name')) + index);
        }

        enable_autocomplete(
            $this, get_autocomplete_opts(vocab_type)
        );
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
      fix_clone_id($cloneElem);

      var vocab_type = clean_input_name($cloneElem.attr('name'))
          .replace(/generic_file_/, '')
          .replace(/collection_/, '');

      if (autocomplete_vocab.url_var.toString().match(vocab_type)) {
          enable_autocomplete($cloneElem, get_autocomplete_opts(vocab_type));
      }
  }

  function enable_autocomplete(element, auto_opts) {
      element.bind( "keydown", function( event ) {
          if ( event.keyCode === $.ui.keyCode.TAB &&
                  $( this ).data( "autocomplete" ).menu.active ) {
              event.preventDefault();
          }
      }).autocomplete(auto_opts)
  }

  $('.multi_value.form-group').manage_fields({add: setup_autocomplete});
});
