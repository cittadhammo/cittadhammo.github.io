$(document).ready(function() {
  $('.lightbox-gallery').magnificPopup({
    delegate: 'a.mfp-image',
    type: 'image',
    gallery: {
      enabled: true,
      navigateByImgClick: false, // HERE: Changed to false globally
      preload: [0,1]
    },
    callbacks: {
      afterChange: function() {
        // Cleanup from previous item (original, as it doesn't touch the button code)
        this.content.find('.fullscreen-map-icon-in-lightbox').remove();

        var mapUrl = this.currItem.el.attr('data-map-url');
        var mfpImg = this.content.find('.mfp-img'); // Get the image element

        // Ensure clicking the image does nothing, regardless of map status
        mfpImg.off('click').on('click.mfpMap', function(e) {
          e.preventDefault(); // Prevent any default actions
          e.stopPropagation(); // Stop event from bubbling up
        }).css('cursor', 'default'); // Set cursor to default

        // Add fullscreen button if mapUrl exists (PRESERVED FROM YOUR ADJUSTMENTS)
        if (mapUrl) {
          // Set explicit width and height on the <a> tag
          // Calculated width: 500px height * (658/258 aspect ratio) = ~1270px
          var fullscreenIcon = $('<a class="fullscreen-map-icon-in-lightbox" href="' + mapUrl + '" style="display: inline-block; top: 40px; width: 300px; height: 80px;"></a>');
          // Use only fs-off.png and control opacity/shadow via CSS transitions
          var iconImage = $('<img src="/assets/icons/fs-off.png" alt="View Fullscreen Map" style="height: 100%; width: 100%; object-fit: contain; object-position: center; opacity: 0.85; transition: opacity 0.3s ease-in-out, filter 0.3s ease-in-out; filter: drop-shadow(0px 0px 4px rgba(0, 0, 0, 0.4));">');
          
          fullscreenIcon.append(iconImage);
          
          // Implement hover effect using CSS transitions
          fullscreenIcon.on('mouseenter', function() {
            iconImage.css({
                'opacity': 1,
                'filter': 'drop-shadow(0px 0px 8px rgba(0, 0, 0, 0.7))' // Stronger shadow for hover
            });
          }).on('mouseleave', function() {
            iconImage.css({
                'opacity': 0.85,
                'filter': 'drop-shadow(0px 0px 4px rgba(0, 0, 0, 0.4))' // Subtle shadow for non-hovered state
            });
          });

          this.content.find('figure').append(fullscreenIcon);
        }      }
    }
  });
});
