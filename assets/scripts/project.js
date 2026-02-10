(function($) {
    $(function() {
        // --- Sticky Function Definition ---
        function sticky() {
            var w = $(window).width();
            var $article = $('.project article');

            if (w < 750) {
                // Detach sticky below 750px
                $article.trigger('sticky_kit:detach');
            } else {
                var headerHeight = $('.header').outerHeight() || 0;
                
                // Calculate the effective offset to allow the article to scroll up 
                // until its top edge is at the desired sticky point (Header Height)
                
                // 1. Current scroll position
                var scrollTop = $(window).scrollTop(); 
                
                // 2. Article's position relative to the document
                var articleTop = $article.offset().top; 

                // 3. Calculate the offset needed to start sticking only when the 
                // article's top aligns with the desired viewport position.
                // This lets the element scroll until its top edge is at headerHeight.
                var effectiveOffset = articleTop - scrollTop - headerHeight;
                
                // Ensure offset is not negative (though it shouldn't be for initial load)
                if (effectiveOffset < 0) {
                    effectiveOffset = 0;
                }

                $article.stick_in_parent({
                    offset_top: effectiveOffset 
                });

                // **CRITICAL FIX:** Force Sticky Kit to recalculate its position
                $article.trigger("sticky_kit:recalc");
            }
        }

        // --- Height Synchronization Function ---
        function updateAsideMinHeight() {
            const article = $("article");
            const height = article.height() + 48;
            $(".project aside").css("min-height", height);

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

    // --- ScrollReveal ---
    var sr = ScrollReveal({
        origin   : "bottom",
        distance : "64px",
        duration : 900,
        delay    : 0,
        scale    : 1
    });
    sr.reveal('.project img.load-hidden, .map-icon.load-hidden');

}(jQuery));