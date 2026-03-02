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
      {% assign first_area = site.data.areas | first %}
      {% if first_area %}
        {% assign hide_hero_on_scroll_cue = site.theme.home_hero_hide_on_scroll_cue %}
        {% if hide_hero_on_scroll_cue == nil %}
          {% assign hide_hero_on_scroll_cue = true %}
        {% endif %}
        <a class="home-hero-scroll-cue" href="#{{ first_area.name | slugify }}" data-hide-hero-on-click="{{ hide_hero_on_scroll_cue | jsonify }}" aria-label="Scroll to content">
          <img src="{{ '/assets/icons/previous-white.png' | relative_url }}" alt="" width="56" height="56" loading="lazy" decoding="async">
        </a>
      {% endif %}
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
