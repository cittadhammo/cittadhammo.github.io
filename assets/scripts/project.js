(function($) {
    $(function() {
        // Track last offset for sticky header to avoid unnecessary detach/re-init
        var lastStickyOffset = null;

        // --- Sticky Function Definition ---
        function sticky() {
            var w = $(window).width();
            var $article = $('.project article');

            if (w < 750) {
                // Detach sticky below 750px
                $article.trigger('sticky_kit:detach');
                lastStickyOffset = null;
            } else {
                var headerHeight = $('.header').outerHeight() || 0;
                var scrollTop = $(window).scrollTop(); 
                var articleTop = $article.offset().top; 
                var isHeaderSticky = $('body').hasClass('header-sticky');
                var effectiveOffset = isHeaderSticky
                    ? Math.max(headerHeight, articleTop - scrollTop - headerHeight)
                    : Math.max(0, articleTop - scrollTop - headerHeight);

                // Sticky-kit caches `q` (offset_top) on first init — recalc
                // doesn't update it. Force detach+re-init when offset changes.
                if (isHeaderSticky && effectiveOffset !== lastStickyOffset) {
                    lastStickyOffset = effectiveOffset;
                    $article.trigger('sticky_kit:detach');
                    $article.stick_in_parent({ offset_top: effectiveOffset });
                    // Trigger scroll to apply sticky position immediately,
                    // preventing visible flicker between detach and re-stick.
                    $(window).trigger('scroll');
                } else {
                    $article.stick_in_parent({ offset_top: effectiveOffset });
                    $article.trigger("sticky_kit:recalc");
                }
            }
        }

        // --- Height Synchronization Function ---
        function updateAsideMinHeight() {
            var w = $(window).width();
            const article = $("article");
            const $aside = $(".project aside");

            if (w < 750) {
                // On mobile, clear the min-height to avoid gaps
                $aside.css("min-height", "");
            } else {
                const height = article.height() + 48;
                $aside.css("min-height", height);
            }

            // Recalculate sticky after height changes
            sticky(); 
        }

        // --- Event Handlers ---

        // 1. Run immediately on DOM Ready
        sticky();
        updateAsideMinHeight();

        // 2. Run on window load, resize, and scroll (to adjust sticky position)
        $(window).on('load resize scroll', function() {
            sticky();
        });
        
        // Use a slight timeout on resize to avoid rapid calculation during resizing
        $(window).on('resize', function() {
            setTimeout(updateAsideMinHeight, 50);
        });
    });

    if (typeof window.ScrollReveal === "function") {
        var sr = ScrollReveal({
            origin   : "bottom",
            distance : "64px",
            duration : 900,
            delay    : 0,
            scale    : 1
        });
        sr.reveal('.project img.load-hidden, .map-icon.load-hidden');
    }

}(jQuery));
