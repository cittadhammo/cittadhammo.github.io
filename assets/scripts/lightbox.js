$(document).ready(function() {
  $('.lightbox-gallery').magnificPopup({
    delegate: 'a.mfp-image',
    type: 'image',
    gallery: {
      enabled: true,
      navigateByImgClick: true,
      preload: [0,1] // Will preload 0 - before current, 1 - after current
    },
    image: {
      tError: '<a href="%url%">The image #%curr%</a> could not be loaded.'
    }
  });
});
