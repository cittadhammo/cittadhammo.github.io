---
layout: home1
title: Home
---

<h1 class="cover-title rouge-first" > DhammaCharts </h1>
 
<img class= "cover load-hidden" src="{{ site.baseurl }}/assets/icons/logoR.png" alt="Cover">

{% for area in site.data.areas %}
<div style="text-align: center; font-size: larger;">
  <a class= "black-under" href='{{ site.baseurl | append: "/" | append: area.name | append: ".html"}}'>{{ area.title }}</a>
</div>
{% endfor %}

