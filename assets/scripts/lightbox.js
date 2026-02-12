$(document).ready(function() {
  $('.lightbox-gallery').magnificPopup({
    delegate: 'a.mfp-image',
    type: 'image',
    image: {
      titleSrc: function(item) {
        return item.el.attr('data-title') || '';
      }
    },
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
        var siteBaseurl = (window.SITE && window.SITE.baseurl) ? window.SITE.baseurl : '';
        // Normalize to avoid protocol-relative URLs like //assets/... when baseurl is "/".
        siteBaseurl = siteBaseurl.replace(/\/+$/, '');

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
          // Use only fs-off.png and keep visual treatment in CSS for theme-aware styling.
          var iconImage = $(`<img src="${siteBaseurl}/assets/icons/fs-off.png" alt="View Fullscreen Map" style="height: 100%; width: 100%; object-fit: contain; object-position: center;">`);
          
          fullscreenIcon.append(iconImage);

          this.content.find('figure').append(fullscreenIcon);
        }
      }
    }
  });
});
