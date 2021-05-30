---
permalink: assets/main
---
{%- capture alljs -%}
  {%- include_relative _jquery-slim.min.js -%}
  {%- include_relative _bootstrap.min.js -%}
  {%- include_relative _katex.min.js -%}
  {%- include_relative _auto-render.min.js -%}
  {%- include_relative _custom.js -%}
{%- endcapture -%}
{{- alljs | uglify -}}
