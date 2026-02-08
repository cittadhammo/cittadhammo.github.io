---
layout: home
title: Home
---
{% for area in site.data.areas %}
  {% include headerCustom.html subTitle=area.title inverted=true area_name=area.name %}
  {% include itemsList.md area = area.name %}
{% endfor %}
