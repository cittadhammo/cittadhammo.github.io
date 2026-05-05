(function () {
  function isImageLink(value) {
    return /\.(png|jpe?g|webp|gif)$/i.test(value);
  }

  function normalizeWikilinkTarget(raw) {
    var value = (raw || "").trim();
    value = value.replace(/^!?\[\[/, "").replace(/\]\]$/, "");
    value = value.split("|")[0].trim();
    return value;
  }

  function buildImageHtml(target, label, allowNoExt) {
    var cleanTarget = normalizeWikilinkTarget(target);
    if (!cleanTarget) return null;
    if (!isImageLink(cleanTarget) && !allowNoExt) return null;

    var base = cleanTarget.replace(/\.[^.]+$/, "");
    var encodedBase = encodeURI(base);
    var ext = window.PAGE_IMAGE_EXT || "webp";
    var baseurl = window.PAGE_BASEURL || "";
    baseurl = baseurl.replace(/\/+$/, "");
    var lightHref = baseurl + "/assets/images/" + encodedBase + "/medium." + ext;
    var src = baseurl + "/assets/images/" + encodedBase + "/medium." + ext;
    var alt = (label && label.trim()) ? label.trim() : cleanTarget.split("/").pop();

    return (
      '<a class="mfp-image page-inline-image-link" href="' + lightHref + '" data-light-href="' + lightHref + '">' +
      '<img class="page-inline-image" src="' + src + '" data-light-src="' + src + '" alt="' + alt.replace(/"/g, "&quot;") + '" loading="lazy">' +
      "</a>"
    );
  }

  function replaceWikilinksInTextNode(textNode) {
    var text = textNode.nodeValue;
    var regex = /!?\[\[([^\]]+)\]\]/g;
    var hasMatch = false;
    var lastIndex = 0;
    var fragment = document.createDocumentFragment();
    var match;

    while ((match = regex.exec(text)) !== null) {
      var full = match[0];
      var inner = match[1];
      var isEmbed = full.indexOf("![[") === 0;
      var parts = inner.split("|");
      var target = normalizeWikilinkTarget(full);
      var label = parts.length > 1 ? parts.slice(1).join("|") : "";
      var hasKnownImageExt = /\.(png|jpe?g|webp|gif)$/i.test(target);
      var html = buildImageHtml(target, label, isEmbed || !hasKnownImageExt);

      if (!html) continue;
      hasMatch = true;

      if (match.index > lastIndex) {
        fragment.appendChild(document.createTextNode(text.slice(lastIndex, match.index)));
      }

      var temp = document.createElement("span");
      temp.innerHTML = html;
      while (temp.firstChild) fragment.appendChild(temp.firstChild);
      lastIndex = match.index + full.length;
    }

    if (!hasMatch) return;

    if (lastIndex < text.length) {
      fragment.appendChild(document.createTextNode(text.slice(lastIndex)));
    }

    textNode.parentNode.replaceChild(fragment, textNode);
  }

  function transformWikilinkImages(container) {
    var walker = document.createTreeWalker(container, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        if (!node.nodeValue || node.nodeValue.indexOf("[[") === -1) {
          return NodeFilter.FILTER_REJECT;
        }

        var parent = node.parentNode;
        if (!parent) return NodeFilter.FILTER_REJECT;

        var tag = parent.tagName;
        if (!tag) return NodeFilter.FILTER_ACCEPT;

        var blocked = { A: true, CODE: true, PRE: true, SCRIPT: true, STYLE: true, TEXTAREA: true };
        return blocked[tag] ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT;
      }
    });

    var nodes = [];
    while (walker.nextNode()) {
      nodes.push(walker.currentNode);
    }
    nodes.forEach(replaceWikilinksInTextNode);
  }

  function initLightbox(container) {
    if (typeof window.jQuery === "undefined" || typeof window.jQuery.fn.magnificPopup === "undefined") {
      return;
    }

    var $container = window.jQuery(container);
    if ($container.find("a.mfp-image").length === 0) return;

    $container.magnificPopup({
      delegate: "a.mfp-image",
      type: "image",
      gallery: {
        enabled: true,
        navigateByImgClick: true,
        preload: [0, 1]
      }
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    var container = document.getElementById("page-content");
    if (!container) return;

    transformWikilinkImages(container);
    initLightbox(container);
  });
})();
