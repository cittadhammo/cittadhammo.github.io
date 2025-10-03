---
layout: map
---

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>The Dhamma Citadel</title>
    <link rel="stylesheet" href="{{ site.baseurl }}/assets/lib/ol/ol.css">
    <script src="{{ site.baseurl }}/assets/lib/ol/ol.js"></script>
    
    {% include head.html %}

    <style>
        html, body { margin: 0; height: 100%; width: 100%; overflow: hidden;   display: flex;
  flex-direction: column; }
        #map { width: 100%; height: 100%; background-color: white;   flex-grow: 1; 
  /* 5. Start from the bottom of the header and go to the screen bottom */
  overflow-y: auto; /* Allows the content inside .map to scroll */}
        .ol-control { font-size: 17px; }
        .cross {
            top: 0.5em;
            left: 0.5em;
            float: right;
		}
        .cross button {
            background: white;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .cross button:hover,
        .cross button:focus {
            opacity: 1;
        }
        .cross button img {
            width: 13px;
            height: 13px;
            display: block;
            object-fit: contain;
        }
        .ol-zoom {
            top: 2.5em !important;  
        }
        .ol-control button {
            color: black !important;
        }        
        /* Mobile adjustments */
        @media (max-width: 480px) {
            .cross {
                top: 0.5em;
                left: 0.5em;
                transform: scale(0.8); /* smaller button */
            }
            .cross button img {
                width: 17px;
                height: 17px;
            }
            .ol-zoom {
                top: 3em !important;  /* push zoom buttons further down */
                transform: scale(0.8); /* smaller button */
            }
        }
    </style>
</head>

<body>

    {%- assign cols = site.collections -%}
    {%- for col in cols -%}
        {%- assign docs = col.docs -%}
        {%- for doc in docs -%}
            {%- if doc.path == "_charts/digital/dhamma-citadel.md" -%}
                {%- assign link = doc.url | prepend: site.baseurl -%}
            {%- endif -%}
        {%- endfor -%}    
    {%- endfor -%}
    {% assign cols = site.collections %}

    <div class="map-header">
        {% include header2.html link=link %}
    </div>
    
    <div id="map" class="map"></div>
    <script>
        const width = 9933;
        const height = 9933;
        const extent = [0, 0, width, width];
        // const extent = [0, 0, 1, 1]; would work as well, 
        // google layour create a square map all the time ,sorry

        // previous button with image
        const button = document.createElement("button");
        const img = document.createElement("img");
        img.src = "/assets/icons/previous.png";
        img.alt = "Previous";
        button.appendChild(img);

        {%- assign cols = site.collections -%}
        {%- for col in cols -%}
            {%- assign docs = col.docs -%}
            {%- for doc in docs -%}
                {%- if doc.path == "_charts/digital/dhamma-citadel.md" -%}
                    {%- assign link = doc.url | prepend: site.baseurl -%}
                {%- endif -%}
            {%- endfor -%}    
        {%- endfor -%}
        {% assign cols = site.collections %}

        const handle = function (e) {
            window.open("{{ link }}", "_self");
        };
        button.addEventListener("click", handle, false);
		
        const element = document.createElement("div");
		element.className = "cross ol-unselectable ol-control";
		element.appendChild(button);

		const OneControl = new ol.control.Control({
			element: element
		});

        // end cross button

        const projection = new ol.proj.Projection({
            code: "pixels",
            units: "pixels",
            extent: extent,
        });

        const overlay = new ol.Overlay({
            element: document.createElement("div"),
        });
        const isMobile = window.innerWidth <= 480; // or 768 adjust breakpoint as needed

        const map = new ol.Map({
            controls: [],  // empty array means no default controls

            layers: [
                new ol.layer.Tile({
                    preload: Infinity,
                    extent: extent,
                    source: new ol.source.TileImage({
                        url: "{{ site.baseurl }}/assets/images/A0SM-DhammaCitadel/tiles/{z}/{y}/{x}.webp",
                    })
                })
            ],
            overlays: [overlay],
            target: "map",
            view: new ol.View({
                projection: projection,
                center: ol.extent.getCenter(extent),
                zoom: isMobile ? 1 : 2,   // zoom 1 on mobile, 2 on desktop
                maxZoom: 6
            }),
            interactions: [
                new ol.interaction.DragPan(),
                new ol.interaction.MouseWheelZoom(),
                new ol.interaction.DoubleClickZoom(),
                new ol.interaction.KeyboardPan(),
                new ol.interaction.KeyboardZoom(),
                new ol.interaction.PinchZoom()
                // no DragRotate, no PinchRotate
            ],
        });
        if (isMobile) {
            map.addControl(OneControl);
        }
        // cursor

        map.getViewport().style.cursor = "-webkit-grab";
        map.on("pointerdrag", function (evt) {
            map.getViewport().style.cursor = "-webkit-grabbing";
        });

        map.on("pointerup", function (evt) {
            map.getViewport().style.cursor = "-webkit-grab";
        });
    </script>
</body>