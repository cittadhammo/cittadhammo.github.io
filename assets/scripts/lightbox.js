$(document).ready(function() {
  $('.lightbox-gallery').magnificPopup({
    delegate: 'a.mfp-image',
    type: 'image',
    gallery: {
      enabled: true,
      navigateByImgClick: true, // Default state - will be overridden per-item
      preload: [0,1]
    },
    callbacks: {
      afterChange: function() {
        // Cleanup from previous item
        this.content.off('click.mfpMap');
        this.content.find('.mfp-img').css('cursor', '');
        this.content.find('.fullscreen-map-icon-in-lightbox').remove();

        var mapUrl = this.currItem.el.attr('data-map-url');
        var mfpImg = this.content.find('.mfp-img');

        // Always disable default Magnific Popup image navigation
        this.st.gallery.navigateByImgClick = false;
        
        if (mapUrl) {
          // If it's a map image, make it clickable to the map link
          // We need to stop propagation and prevent default to override Magnific Popup's behavior
          mfpImg.off('click').on('click.mfpMap', function(e) {
            e.preventDefault(); // Prevent default link behavior or Magnific Popup's next/prev
            e.stopPropagation(); // Stop event from bubbling up to parent elements
            window.location.href = mapUrl;
          }).css('cursor', 'pointer');
        } else {
          // If it's not a map image, clicking it should do nothing
          // Ensure no click handlers are active, and stop propagation just in case
          mfpImg.off('click').on('click.mfpMap', function(e) {
            e.preventDefault(); // Prevent any potential default actions
            e.stopPropagation(); // Stop event from bubbling up
          }).css('cursor', 'default');
        }

        // Add fullscreen button if mapUrl exists (for any case)
        if (mapUrl) {
          var fullscreenIcon = $('<a class="fullscreen-map-icon-in-lightbox" href="' + mapUrl + '"></a>');
          // Use only fs-off.png and control opacity/shadow via CSS transitions
          var iconImage = $('<img src="/assets/icons/fs-off.png" alt="View Fullscreen Map" style="height: 96px; width: auto; object-fit: contain; object-position: center; opacity: 0.85; transition: opacity 0.3s ease-in-out, filter 0.3s ease-in-out; filter: drop-shadow(0px 0px 4px rgba(0, 0, 0, 0.4));">');
          
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
        }      },
      beforeClose: function() {
        // Reset to default on close, just in case
        this.st.gallery.navigateByImgClick = true;
      }
    }
  });
});
