if (typeof window.ScrollReveal === "function") {
  var sr = ScrollReveal({
	origin   : "bottom",
	distance : "64px",
	duration : 800,
	delay    : 0,
	scale    : 1
  });
  sr.reveal('.projects-list a');
}

if (typeof window.Masonry !== "undefined") {
  var grid = document.querySelector('.projects-list');
  if (grid) {
    grid.classList.add('masonry');
    var msnry = new Masonry(grid, {
      columnWidth: '.projects-list li',
      itemSelector: 'li',
      gutter: 24
    });
    if (typeof imagesLoaded === "function") {
      imagesLoaded(grid, function () {
        msnry.layout();
      });
    }
  }
}

document.addEventListener("DOMContentLoaded", function () {
  var scrollCue = document.querySelector(".home-hero-scroll-cue");
  var hero = document.querySelector(".home-hero");
  if (!scrollCue) return;

  scrollCue.addEventListener("click", function (event) {
    var href = scrollCue.getAttribute("href") || "";
    var hideAttr = (scrollCue.getAttribute("data-hide-hero-on-click") || "true").trim().toLowerCase();
    var hideHeroOnClick = !(hideAttr === "false" || hideAttr === "0" || hideAttr === "no");
    if (href.charAt(0) !== "#") return;

    var target = document.getElementById(href.slice(1));
    if (!target) return;

    event.preventDefault();
    var prefersReducedMotion = window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    var targetTop = target.getBoundingClientRect().top + window.pageYOffset;
    window.scrollTo({
      top: targetTop,
      behavior: prefersReducedMotion ? "auto" : "smooth"
    });

    window.setTimeout(function () {
      if (hideHeroOnClick) {
        var heroHeight = hero ? hero.offsetHeight : 0;
        document.documentElement.classList.add("has-initial-hash");
        if (heroHeight > 0) {
          // Removing the hero shrinks document height; compensate so the
          // viewport stays anchored on the same section.
          window.scrollTo({
            top: Math.max(window.pageYOffset - heroHeight, 0),
            behavior: "auto"
          });
        }
      }
      if (hideHeroOnClick) {
        if (window.history && typeof window.history.replaceState === "function") {
          window.history.replaceState(null, "", href);
        } else {
          window.location.hash = href;
        }
      }
    }, prefersReducedMotion ? 0 : 420);
  });
});
