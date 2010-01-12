// // // // // // // // // // // // // // // // // // // // // // // // 
// Entities/Show

$(document).ready(function(){
  // // // // // // // // // // // // // // // // // // // // // // //
  // Show more info
  $('.dataset_description.large ul li .info').toggle(function(){
    $(this).find('.more').show();
  }, function(){
    $(this).find('.more').hide();
  });
  
  // // // // // // // // // // // // // // // // // // // // // // //
  // Sortable lists
  $.getScript('/javascripts/jquery.ui.sortable.js', function(){
    // // // // // // // // // // // // // // // // // // // // // // //
    // Sortables for import settings
    
    $("#all_field_descriptions ul").sortable({connectWith: '#importable_field_descriptions ul', update: update_import_settings});
    $("#importable_field_descriptions ul").sortable({connectWith: '#all_field_descriptions ul', update: update_import_settings});
  });
});

var update_import_settings = function(){
  var settings = {};
  var counter = 1;
  $("#importable_field_descriptions ul li").each(function(){
    $(this).find("strong").text(counter);
    settings[$(this).attr('id').replace('field_description_', '')] = counter++;
  });
  $("#dataset_description_import_settings").val($.param(settings));
};


// // // // // // // // // // // // // // // // // // // // // // // // 
// Field descriptions visibility

var field_description_visibility_save = null;
$(document).ready(function(){
  $("input.field_description[type=checkbox]").click(function(){
    clearTimeout(field_description_visibility_save);
    field_description_visibility_save = setTimeout(function(){
      // Extract information and save it to server
      var data = $("input.field_description[type=checkbox]").serialize();
      var url = $("a.save_field_descriptions_visibility").attr("href");
      $.post(url, data);
    }, 200);
  });
});

// // // // // // // // // // // // // // // // // // // // // // // // 
// Turning on and off all items at once in DatasetDescriptionsController:visibility

$(document).ready(function(){
  $("a.switch_visibility").click(function(){
    var table = $(this).parents("table:first");
    var target = $(this).attr("href").replace("#", "");
    var inputs = table.find("td."+target).find("input[type=checkbox]");
    var value = inputs[0].checked ? 1 : 0
    if(value==1)
    {
      inputs.attr('checked', false);
    }
    else
    {
      inputs.attr('checked', true);
    }
    
    return false;
  });
});

// // // // // // // // // // // // // // // // // // // // // // // // 
// Import template picker

$(document).ready(function(){
  $("#import_file_template").change(function(){
    // Find data for selected value
    var template_id = $(this).val();
    var template = $.grep(import_templates, function(i){return i.id==template_id});
    template = template[0];
    if(template)
    {
      $("#import_file_col_separator").val(template.col_separator);
      $("#import_file_number_of_header_lines").val(template.number_of_header_lines);
    };
  }).change();
});

$(document).ready(function(){
  $("#settings").toggle();
  $("a.toggle_settings").click(function(){
    $("#settings").toggle();
    return false;
  });
});
