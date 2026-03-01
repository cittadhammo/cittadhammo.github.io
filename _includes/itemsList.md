{% assign area_name = include.area %}

{% assign area = site.data.areas | where: 'name', area_name | first %}

{% assign items = site[area_name] %}

{% for category in area.categories %}
  {% assign category_name = category.name | remove: ' ' %}
  {% capture category_title %}
    {% if category.title %}
      {{ category.title }}
    {% else %}
      {% include humanize_name.html value=category.name %}
    {% endif %}
  {% endcapture %}
  {% assign category_title = category_title | strip %}
  <section class="projects">
    <div class="container">
      <h1 class="cat-title">{{ category_title }}</h1>
      <ul class="projects-list">
        {% for item in items %}
          {% assign parent = item.url | split: '/' | pop | last %}
          {% if parent == category.name %}
            <li class="load-hidden">
              <a href="{{ item.url | relative_url }}">
                <div class="img-wrapper">
                  {% assign image = item.images | first %}
                  {% assign image_entry = image %}
                  {% if image_entry == nil and item.image %}
                    {% assign image_entry = item.image %}
                  {% endif %}
                  {% assign image_name = image_entry.name | default: image_entry | to_s | strip | remove: '[[' | remove: ']]' | split: '|' | first | strip %}
                  {% assign img = image_name | split: '.' | first %}
                  {% assign dark_suffix = site.darkify.suffix | default: 'dark' %}
                  {% assign has_dark_variant = true %}
                  {% if image and image.dark == true %}
                    {% assign has_dark_variant = false %}
                  {% endif %}
                  {% if image_name != '' %}
                    <img
                      src="{{ '/assets/images/' | append: img | append: '/small.' | append: site.img_ext | relative_url }}"
                      data-light-src="{{ '/assets/images/' | append: img | append: '/small.' | append: site.img_ext | relative_url }}"
                      {% if has_dark_variant %}
                        data-dark-src="{{ '/assets/images/' | append: img | append: '/small-' | append: dark_suffix | append: '.' | append: site.img_ext | relative_url }}"
                      {% endif %}
                      alt="{{ image_name }}"
                      loading="lazy"
                      style="aspect-ratio: {{ site.data.size[img].small }};"
                    >
                  {% endif %}
                </div>
                <h3>{{ item.title }}</h3>
                <span class="h2">{{ item.subtitle }}</span>
              </a>
            </li>
          {% endif %}
        {% endfor %}
      </ul>
    </div>
  </section>
{% endfor %}
