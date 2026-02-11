---
layout: home
title: Home
---
{% for area in site.data.areas %}
  {% capture area_title %}
    {% if area.title %}
      {{ area.title }}
    {% else %}
      {% include humanize_name.html value=area.name %}
    {% endif %}
  {% endcapture %}
  {% assign area_title = area_title | strip %}
  {% include header.html subTitle=area_title inverted=true area_name=area.name show_theme_toggle=forloop.first %}
  {% include itemsList.md area = area.name %}
{% endfor %}
