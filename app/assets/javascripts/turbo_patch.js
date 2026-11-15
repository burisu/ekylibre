// Don't refresh page when <a href='#'> is clicked
$(document).on('turbo:click', function (event) {
  const href = event.target.getAttribute('href');
  if (href && href.charAt(0) === '#') {
    event.preventDefault()
  }
})
