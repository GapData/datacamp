$(function() {
  $('#overlay, [data-show-license-abort]').click(function(e) {
    $('#overlay').hide();
    $('#pop-up-window').hide();
    e.preventDefault();
  });

  $('[data-show-license]').click(function() {
    var $dataset = $(this);
    if(!$.cookie('license_accepted')) {
      $('#overlay').show();
      $("#pop-up-window [data-license-var-dataset]").html($dataset.data('license-for'));
      $("#pop-up-window [data-license-var-url]").attr('href', $dataset.data('dataset-url'));
      $('#pop-up-window').show();

      $("#pop-up-window form").submit(function(e) {
        setTimeout(function() {
          $('#overlay').hide();
          $('#pop-up-window').hide();
          window.location.href = $dataset.data('dataset-url');
        }, 100);
      });
      return false;
    }
  });

  $('[data-license-dont-show-again]').click(function() {
    $.cookie('license_accepted', '1', { expires: 365, path: '/' });
  });

});
