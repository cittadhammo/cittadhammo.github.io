# How to Revert Lightbox Image Click Behavior

This document outlines the steps to revert the custom behavior implemented for single map images in the Magnific Popup lightbox. After performing these steps, clicking an image inside the lightbox will **not** navigate to the map page. Navigation to the map will only occur by clicking the dedicated "fullscreen" button.

**Context:**
Originally, if there was a single image in the lightbox carousel and it had a `data-map-url` attribute (indicating it's a map), clicking the image inside the lightbox would navigate directly to the map page. This document describes how to undo that specific functionality.

**Instructions to Revert:**

1.  **Open the file:** `/assets/scripts/lightbox.js`
2.  **Locate the `callbacks` object:** Find the `callbacks` object within the Magnific Popup initialization (i.e., `$('.lightbox-gallery').magnificPopup({...});`).
3.  **Replace the `callbacks` object:** Replace the entire `callbacks` object with the content provided in the "Original `callbacks` Object" section below. This will remove the custom single-image map click logic and revert the `navigateByImgClick` setting to its default, static `true` state for all items.
4.  **Verify file content:** After the replacement, ensure that the *entire* `lightbox.js` file content matches the "Original `lightbox.js` Content" block provided below.
5.  **Save the changes:** Save the modified `/assets/scripts/lightbox.js` file.

---

### Original `lightbox.js` Content (to restore the file to this state)

```javascript
$(document).ready(function() {
  $('.lightbox-gallery').magnificPopup({
    delegate: 'a.mfp-image',
    type: 'image',
    gallery: {
      enabled: true,
      navigateByImgClick: true, // This should be true for default behavior
      preload: [0,1]
    },
    callbacks: {
      change: function() {
        var mfpImg = this.content.find('.mfp-img');
        mfpImg.off('click.mfpMap'); // This line should be present for cleanup
      },
      afterChange: function() {
        // This section should only handle the fullscreen button logic
        this.content.find('.fullscreen-map-icon-in-lightbox').remove();
        
        var mapUrl = this.currItem.el.attr('data-map-url');
        if (mapUrl) {
          var fullscreenIcon = $('<a class="fullscreen-map-icon-in-lightbox" href="' + mapUrl + '"></a>');
          fullscreenIcon.append('<img src="/assets/icons/fs300.png" alt="View Fullscreen Map" style="width: 159px; height: 32px;">');
          
          this.content.find('figure').append(fullscreenIcon);
        }
      }
    }
  });
});
```
