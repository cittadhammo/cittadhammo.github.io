$(document).ready(function() {
  $('.lightbox-gallery').magnificPopup({
    delegate: 'a.mfp-image',
    type: 'image',
    gallery: {
      enabled: true,
      navigateByImgClick: true, // Default state
      preload: [0,1]
    },
    callbacks: {
      afterChange: function() {
        // Cleanup from previous item
        this.content.off('click.mfpMap');
        this.content.find('.mfp-img').css('cursor', '');
        this.content.find('.fullscreen-map-icon-in-lightbox').remove();

        var mapUrl = this.currItem.el.attr('data-map-url');

        // Logic for single map image
        if (this.items.length === 1 && mapUrl) {
          // 1. Disable default gallery navigation
          this.st.gallery.navigateByImgClick = false;
          
          // 2. Add our custom click handler
          this.content.on('click.mfpMap', '.mfp-img', function() {
            window.location.href = mapUrl;
          });
          
          // 3. Add visual cue
          this.content.find('.mfp-img').css('cursor', 'pointer');
        } else {
          // For all other cases (multiple images, or single non-map), ensure default is on
          this.st.gallery.navigateByImgClick = true;
        }

        // Add fullscreen button if mapUrl exists (for any case)
        if (mapUrl) {
          var fullscreenIcon = $('<a class="fullscreen-map-icon-in-lightbox" href="' + mapUrl + '"></a>');
          fullscreenIcon.append('<img src="/assets/icons/fs300.png" alt="View Fullscreen Map" style="width: 159px; height: 32px;">');
          this.content.find('figure').append(fullscreenIcon);
        }
      },
      beforeClose: function() {
        // Reset to default on close, just in case
        this.st.gallery.navigateByImgClick = true;
      }
    }
  });
});

