(function($) {
	$(function() {
		$(window).on('load resize', function() {
			sticky();
		});

		function sticky() {
			var w = $(window).width();

			if (w < 750) {
				$('.project article').trigger('sticky_kit:detach');
			} else {
				$('.project article').stick_in_parent({
					offset_top: $('.header').outerHeight()
				});
			}
		}
	});

	var sr = ScrollReveal({
		origin   : "bottom",
		distance : "64px",
		duration : 900,
		delay    : 0,
		scale    : 1
	});

	sr.reveal('.project img');

	const article = $("article");
	const height = article.height() + 48;
	$(".project aside").css("min-height", height);

	window.onresize = doALoadOfStuff;

	function doALoadOfStuff() {
	    //do a load of stuff
			const article = $("article");
			const height = article.height() + 48;
			$(".project aside").css("min-height", height);

	}
	
}(jQuery));