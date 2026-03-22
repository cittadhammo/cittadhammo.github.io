$(document).ready(function() {
  var $gallery = $('.lightbox-gallery');
  
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

  $(document).on('click', '.download-lightbox-link', function(e) {
    e.preventDefault();
    var targetIndex = parseInt($(this).data('lightbox-index'), 10);
    if (!isNaN(targetIndex)) {
      var $allLinks = $gallery.find('a.mfp-image');
      var items = [];
      $allLinks.each(function() {
        items.push({
          src: $(this).attr('href'),
          type: 'image',
          title: $(this).data('title') || ''
        });
      });
      
      $.magnificPopup.open({
        items: items,
        gallery: {
          enabled: true
        },
        type: 'image',
        image: {
          titleSrc: function(item) {
            return item.el.attr('data-title') || '';
          }
        },
        callbacks: {
          afterChange: function() {
            this.content.find('.fullscreen-map-icon-in-lightbox').remove();
            var mapUrl = $allLinks.eq(this.currIndex).attr('data-map-url');
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
      }, targetIndex);
    }
  });
});
