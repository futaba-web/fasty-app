// app/assets/config/manifest.js

// 画像
//= link_tree ../images

// Tailwind v4 の出力（tailwindcss:build が生成する app/assets/builds/tailwind.css）
//// まとめて拾うなら:
////   //= link_tree ../builds .css
//= link tailwind.css

// 自作CSS（app/assets/stylesheets 配下をまるっとプリコンパイル）
//// 明示で個別指定したい場合は link を並べてもOK。
//= link_directory ../stylesheets .css
// = link application.css
// = link drawer.css
// = link layout.css
// = link landing.css

//（必要なら）JS バンドルを拾う
//= link_tree ../../javascript .js
//= link_tree ../../../vendor/javascript .js
