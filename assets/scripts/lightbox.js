$(document).ready(function() {
  $('.lightbox-gallery').magnificPopup({
    delegate: 'a.mfp-image',
    type: 'image',
    gallery: {
      enabled: true,
      navigateByImgClick: true, // Re-enable default image click navigation
      preload: [0,1]
    },
    callbacks: {
      change: function() {
        var mfpImg = this.content.find('.mfp-img');
        mfpImg.off('click.mfpMap'); // Always remove previous custom click handlers
      },
      afterChange: function() {
        // Always remove previous icon before adding a new one
        this.content.find('.fullscreen-map-icon-in-lightbox').remove();
        
        var mapUrl = this.currItem.el.attr('data-map-url');
        if (mapUrl) {
          var fullscreenIcon = $('<a class="fullscreen-map-icon-in-lightbox" href="' + mapUrl + '"></a>');
          fullscreenIcon.append('<img src="/assets/icons/fs300.png" alt="View Fullscreen Map" style="width: 159px; height: 32px;">');
          
          // Append to the <figure> element
          this.content.find('figure').append(fullscreenIcon);
        }
      }
    }
  });
});
