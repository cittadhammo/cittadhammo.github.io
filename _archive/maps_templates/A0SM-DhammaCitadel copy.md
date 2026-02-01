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
        html, body { margin: 0; height: 100%; width: 100%; overflow: hidden; display: flex; flex-direction: column; }
        #map { 
            width: 100%; 
            height: 100vh; 
            background-color: white; 
            position: absolute;
            top: 0;
            left: 0;
            z-index: 1;
        }
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
        .ol-control button {
            color: black !important;
        }
        
        /* Header styles */
        .map-header {
            position: relative;
            z-index: 10;
            transition: transform 0.3s ease;
        }
        .map-header.collapsed {
            transform: translateY(-100%);
        }
        
        /* Arrow toggle button */
        .header-toggle {
            position: absolute;
            left: 50%;
            transform: translateX(-50%);
            //bottom: -20px;
            z-index: 20;
            background: transparent;
            border: none;
            cursor: pointer;
            padding: 10px;
            transition: all 0.3s ease;
        }
        .header-toggle:hover .arrow {
            border-color: black;
            opacity: 1;
        }
        .arrow {
            border: solid black;
            border-width: 0 3px 3px 0;
            display: inline-block;
            padding: 8px;
            opacity: 0.5;
            transition: all 0.3s ease;
        }
        .up {
            transform: rotate(-135deg);
            -webkit-transform: rotate(-135deg);
        }
        .down {
            transform: rotate(45deg);
            -webkit-transform: rotate(45deg);
        }
        
        /* When header is collapsed, position toggle at top */
        .map-header.collapsed + .header-toggle {
            bottom: auto;
            top: 10px;
            background: white;
            padding: 8px;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        .map-header.collapsed + .header-toggle .arrow {
            opacity: 1;
        }
        
        /* Mobile adjustments */
        @media (max-width: 480px) {
            .cross {
                top: 0.5em;
                left: 0.5em;
                transform: scale(0.8);
            }
            .cross button img {
                width: 17px;
                height: 17px;
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
    
    <button class="header-toggle" onclick="toggleHeader()" title="Toggle Header">
        <i class="arrow up"></i>
    </button>
    
    <div id="map" class="map"></div>
    <script>
        // Header toggle function
        function toggleHeader() {
            const header = document.querySelector('.map-header');
            const arrow = document.querySelector('.header-toggle .arrow');
            header.classList.toggle('collapsed');
            
            if (header.classList.contains('collapsed')) {
                // Show down arrow when header is hidden
                arrow.classList.remove('up');
                arrow.classList.add('down');
            } else {
                // Show up arrow when header is visible
                arrow.classList.remove('down');
                arrow.classList.add('up');
            }
        }
        
        const width = 9933;
        const height = 9933;
        const extent = [0, 0, width, width];

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
        
        const isMobile = window.innerWidth <= 900; // check if screen is less than 900px

        const map = new ol.Map({
            controls: [],  // empty array means no default controls (removes zoom buttons)
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
        
        // Only add the control on mobile (screen width < 900px)
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