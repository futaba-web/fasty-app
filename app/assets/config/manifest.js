// app/assets/config/manifest.js

// 画像
//= link_tree ../images

// Tailwind v4 の出力（tailwindcss:build が生成する app/assets/builds/tailwind.css）
//= link tailwind.css

// 自作CSS（application.html.erb から読み込んでいるもの）
/*
  <%= stylesheet_link_tag "tailwind",
                          "application",
                          "layout",
                          "drawer",
                          "landing",
                          "devise",
                          "setting",
                          "data-turbo-track": "reload" %>
*/
 //= link application.css
//= link drawer.css
//= link layout.css
//= link landing.css
//= link devise.css
//= link setting.css

// JS バンドル
//= link_tree ../../javascript .js
//= link_tree ../../../vendor/javascript .js
