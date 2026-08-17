---
layout: archive
title: "Projects"
permalink: /projects/
author_profile: true
---

{% include base_path %}

{% assign sorted_projects = site.projects | sort: "date" | reverse %}
{% for post in sorted_projects %}
  {% include archive-single.html type="grid" %}
{% endfor %}