let presets = ["babel-preset-atomic"];

let plugins = ["@babel/plugin-transform-classes"] // this is needed so Disposabale can be extended by ES5-style classes

module.exports = {
  presets: presets,
  plugins: plugins,
  exclude: "node_modules/**",
  sourceMap: true,
}
