---
layout: home
title: Home
---
{% if site.theme.home_hero_landing %}
  <section class="home-hero" aria-label="Home Hero">
    <div class="home-hero-inner container">
      <h1 class="home-hero-title rouge-first">{{ site.title | default: site.author }}</h1>
      <img
        class="home-hero-logo"
        src="{{ '/assets/icons/logo_dark_300.png' | relative_url }}"
        data-dark-src="{{ '/assets/icons/logo_dark_300.png' | relative_url }}"
        {% if site.theme.home_hero_follow_theme != false %}
          data-light-src="{{ '/assets/icons/logo_light_300.png' | relative_url }}"
        {% endif %}
        width="1372"
        height="1372"
        loading="eager"
        fetchpriority="high"
        decoding="async"
        alt="{{ site.title | default: site.author }}"
      >
      <nav class="home-hero-nav" aria-label="Areas">
        {% for area in site.data.areas %}
          {% capture area_title %}
            {% if area.title %}
              {{ area.title }}
            {% else %}
              {% include humanize_name.html value=area.name %}
            {% endif %}
          {% endcapture %}
          {% assign area_title = area_title | strip %}
          <a href="#{{ area.name | slugify }}"><span class="rouge-first">{{ area_title }}</span></a>
        {% endfor %}
      </nav>
    </div>
  </section>
{% endif %}
{% for area in site.data.areas %}
  {% capture area_title %}
    {% if area.title %}
      {{ area.title }}
    {% else %}
      {% include humanize_name.html value=area.name %}
    {% endif %}
  {% endcapture %}
  {% assign area_title = area_title | strip %}
  <section class="home-area" id="area-{{ area.name | slugify }}">
    {% include header.html subTitle=area_title inverted=true area_name=area.name show_theme_toggle=forloop.first %}
    {% include itemsList.md area = area.name %}
  </section>
{% endfor %}
