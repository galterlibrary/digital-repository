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
    'lcsh', 'mesh', 'language', 'creator', 'contributor', 'based_near',
    'subject_geographic', 'subject_name'
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

        enable_autocomplete($this, get_autocomplete_opts(vocab_type));
        enable_person_verify($this, vocab_type);
    });
  }

  function enable_person_verify(element, vocab_type) {
    if (vocab_type != 'creator' && vocab_type != 'contributor') return

    element.on('blur', function() {
      var note_id = this.id + '-ver';
      if ($(this).val() == '') {
        $(this).css('background-color', 'white');
        $('#' + note_id).text('');
        return;
      }

      if (!$('#' + note_id).length) {
        element.parent().before(
            '<li class="input-group" id="' + note_id + '"></li>'
        );
      }

      verify_user($(this).val(), $('#' + note_id), $(this))
    });
  }

  function verify_user(query, node, input) {
    $.getJSON('/authorities/generic_files/verify_user?q=' + query, function(data) {
      if (data.verified) {
        node.html(
            '<span class="glyphicon glyphicon-ok" style="color:green" aria-hidden="true"></span> '
            + '"' + data.standardized_name
            + '" is a valid NU directory name.');
        input.val(data.standardized_name);
        input.css('background-color', '#F0FFF0');
        if (!jQuery.isEmptyObject(data.vivo)) {
            node.append(
                ' <a href="' + data.vivo.profile +
                '" target="_blank">Vivo Profile</a>'
            );
        }
      } else {
        node.html(
            '<span class="glyphicon glyphicon-exclamation-sign" style="color:red" aria-hidden="true"></span>'
            + data.message);
        input.css('background-color', '#FFF8DC');
      }
    });
  }

  // Fix clone's id so it's not duped with origin
  function fix_clone_id(clone) {
      if (/\d/.test(clone.attr('id'))) {
          clone.attr(
              'id', clone.attr('id').replace(/\d+$/, function(n){ return ++n })
          );
      } else {
          clone.attr('id', clone.attr('id') + '1');
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

      $cloneElem.css('background-color', 'white');
      enable_person_verify($cloneElem, vocab_type);
  }

  function enable_autocomplete(element, auto_opts) {
      element.bind( "keydown", function( event ) {
          if ( event.keyCode === $.ui.keyCode.TAB &&
                  $( this ).data( "autocomplete" ).menu.active ) {
              event.preventDefault();
          }
      }).autocomplete(auto_opts)
  }

  function remove_user_verification() {
      $(this).find('li[id$="-ver"]').each(function(idx, li) {
          if (!$('input#' + li.id.replace(/-ver/, '')).length) $(li).remove();
      });
  }

  $('.multi_value.form-group').manage_fields(
      { add: setup_autocomplete, remove: remove_user_verification }
  );
});
