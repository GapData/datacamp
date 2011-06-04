// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function(){
  $("form.search").submit(function(event){
    if(inscription_validate_form(this))
    {
      $.loading($("#search_processing").text());
      // return false;
    }
    else
    {
      return false;
    }
  });
  $("a.search_preloader").click(function(){
    $.loading($("#search_processing").text());
  });
});

$(document).ready(function(){
  if($("#import_status").length > 0) {
    setTimeout(update_import_status, 1000);
  }
});

$.ajaxSetup({
  beforeSend: function(xhr) {
    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
  }
});


var update_import_status = function(){
  if($("#import_status a.refresh").length == 0)
  {
    return;
  }
  var target = $("#import_status a.refresh").attr('href');
  $.getScript(target, function(){
    setTimeout(update_import_status, 2000);
  })
}