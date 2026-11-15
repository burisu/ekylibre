// Setup of the legacy scripts (loaded in config/legacy_javascripts.yml order)

// FIX Browser interoperability
// href function seems to be ineffective
$.rails.href = function (element) {
    return $(element).attr('href');
};

$(document).ready(function() {
  L.Icon.Default.imagePath = '/assets';
  $(".snippet-content > ul > li").click(function(e) {
    localStorage.scrollTop = $('.inner').scrollTop();
  });
  $('.inner').animate({ scrollTop: localStorage.scrollTop }, 0);
  $(".collapse").click(function(){
    localStorage.clear();
  });
});
