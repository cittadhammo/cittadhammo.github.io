---
layout: home
title: Home
---

{% for area in site.data.areas %}
  {% if forloop.first %}
    {% include headerCustom.html subTitle=area.title inverted=true is_first=true area_name=area.name %}
  {% else %}
    {% include headerCustom.html subTitle=area.title inverted=true area_name=area.name %}
  {% endif %}
  {% include itemsList.md area = area.name %}
{% endfor %}

