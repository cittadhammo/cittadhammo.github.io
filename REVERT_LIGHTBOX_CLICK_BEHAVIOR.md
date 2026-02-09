# How to Revert Lightbox Image Click Behavior

This document outlines the steps to revert the lightbox click behavior from "clicking any image does nothing" back to "clicking any image goes to the next one". The fullscreen button functionality will remain unchanged by this revert.

**Instructions to Revert:**

1.  **Open the file:** `/assets/scripts/lightbox.js`
2.  **Replace the entire content of the file** with the code block provided below. This code contains the logic that makes clicking any image in the lightbox advance to the next one.

---

### Code to Restore for "Click Image to Go Next" Behavior

```javascript
$(document).ready(function() {
  $('.lightbox-gallery').magnificPopup({
    delegate: 'a.mfp-image',
    type: 'image',
    gallery: {
      enabled: true,
      navigateByImgClick: true, // This is the new behavior
      preload: [0,1]
    },
    callbacks: {
      afterChange: function() {
        // Cleanup from previous item
        this.content.find('.fullscreen-map-icon-in-lightbox').remove();

        var mapUrl = this.currItem.el.attr('data-map-url');

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
        }
      }
    }
  });
});
```