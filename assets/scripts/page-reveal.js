(function () {
  if (typeof window.ScrollReveal !== "function") return;

  document.addEventListener("DOMContentLoaded", function () {
    var sr = window.ScrollReveal({
      origin: "bottom",
      distance: "48px",
      duration: 700,
      delay: 0,
      scale: 1
    });

    sr.reveal(
      "#page-content .link-item, #page-content .inDiv, #page-content img",
      { interval: 80 }
    );
  });
})();
