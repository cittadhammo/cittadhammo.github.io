$(document).ready(function() {
  var $gallery = $('.lightbox-gallery');
  var $externalLinks = $('.download-lightbox-link');
  var mfpInstance = null;
  
  function processGallery() {
    var currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
    console.log('[processGallery] Running, theme:', currentTheme);
    
    $gallery.find('li.variant-clone').remove();
    
    $gallery.find('a.mfp-image').each(function() {
      var $link = $(this);
      
      var lightHref = $link.attr('data-light-href');
      var darkHref = $link.attr('data-dark-href');
      var lightMapUrl = $link.attr('data-light-map-url');
      var darkMapUrl = $link.attr('data-dark-map-url');
      var title = $link.attr('data-title') || '';
      var galleryIndex = $link.attr('data-gallery-index');
      
      if (!lightHref || !darkHref || lightHref === darkHref) {
        return;
      }
      
      var isLightVariant = (currentTheme === 'light');
      console.log('[processGallery] Link:', galleryIndex, 'lightMap:', lightMapUrl, 'darkMap:', darkMapUrl, 'isLight:', isLightVariant);
      
      var $clone = $link.clone();
      $clone.addClass('variant-clone');
      
      if (isLightVariant) {
        $clone.attr('href', darkHref);
        $clone.attr('data-theme-variant', 'dark');
        $clone.attr('data-title', title + ' (DARK)');
        if (darkMapUrl) {
          $clone.attr('data-map-url', darkMapUrl);
        }
        if (lightMapUrl) {
          $link.attr('data-map-url', lightMapUrl + '?theme=light');
        }
      } else {
        $clone.attr('href', lightHref);
        $clone.attr('data-theme-variant', 'light');
        if (lightMapUrl) {
          $clone.attr('data-map-url', lightMapUrl + '?theme=light');
        }
        $link.attr('data-title', title + ' (DARK)');
        if (darkMapUrl) {
          $link.attr('data-map-url', darkMapUrl);
        }
      }
      
      $clone.attr('data-gallery-index', parseFloat(galleryIndex) + 0.5);
      
      var $parentLi = $link.closest('li');
      if ($parentLi.length) {
        $parentLi.after($('<li class="variant-clone" style="display: none;"></li>').append($clone));
      } else {
        $clone.insertAfter($link).wrap('<li class="variant-clone" style="display: none;"></li>');
      }
    });
  }
  
  function processExternalLinks() {
    var currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
    
    $externalLinks.each(function() {
      var $link = $(this);
      
      var lightHref = $link.attr('data-light-href');
      var darkHref = $link.attr('data-dark-href');
      var title = $link.attr('data-title') || '';
      
      if (!lightHref || !darkHref || lightHref === darkHref) {
        return;
      }
      
      var isLightVariant = (currentTheme === 'light');
      
      if (isLightVariant) {
        $link.attr('data-title', title);
      } else {
        $link.attr('href', darkHref);
        $link.attr('data-title', title + ' (DARK)');
      }
    });
  }
  
  function openLightboxAtIndex(index) {
    if (mfpInstance) {
      mfpInstance.galleryIndex = index;
      mfpInstance.updateItemHTML();
    }
  }
  
  function initGallery() {
    processGallery();
    processExternalLinks();
    
    $gallery.magnificPopup({
      delegate: 'a.mfp-image',
      type: 'image',
      image: {
        titleSrc: function(item) {
          return item.el.attr('data-title') || '';
        }
      },
      gallery: {
        enabled: true,
        navigateByImgClick: false,
        preload: [0,1]
      },
      callbacks: {
        afterChange: function() {
          this.content.find('.fullscreen-map-icon-in-lightbox').remove();

          var mapUrl = this.currItem.el.attr('data-map-url');
          var mfpImg = this.content.find('.mfp-img');
          var siteBaseurl = (window.SITE && window.SITE.baseurl) ? window.SITE.baseurl : '';
          siteBaseurl = siteBaseurl.replace(/\/+$/, '');

          mfpImg.off('click').on('click.mfpMap', function(e) {
            e.preventDefault();
            e.stopPropagation();
          }).css('cursor', 'default');

          if (mapUrl) {
            var fullscreenIcon = $('<a class="fullscreen-map-icon-in-lightbox" href="' + mapUrl + '" style="display: inline-block; top: 40px; width: 300px; height: 80px;"></a>');
            var iconImage = $(`<img src="${siteBaseurl}/assets/icons/fs-off.png" alt="View Fullscreen Map" style="height: 100%; width: 100%; object-fit: contain; object-position: center;">`);
            fullscreenIcon.append(iconImage);
            this.content.find('figure').append(fullscreenIcon);
          }
        }
      }
    });
    
    $externalLinks.on('click', function(e) {
      e.preventDefault();
      var $link = $(this);
      var index = parseInt($link.attr('data-gallery-index'), 10);
      var $targetLink = $gallery.find('a.mfp-image[data-gallery-index="' + index + '"]').first();
      if ($targetLink.length) {
        $targetLink.click();
      }
    });
  }
  
  var observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.attributeName === 'data-theme') {
        setTimeout(function() {
          processGallery();
          processExternalLinks();
        }, 300);
      }
    });
  });
  
  observer.observe(document.documentElement, { attributes: true });
  
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initGallery);
  } else {
    initGallery();
  }
});
