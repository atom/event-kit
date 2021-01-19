let presets = ["babel-preset-atomic"];

let plugins = process.env.PARCEL_ENV
  ? [] // the optimized bundle uses ES6 class
  : ["@babel/plugin-transform-classes"] // this is needed so Disposabale can be extended by ES5-style classes

module.exports = {
  presets: presets,
  plugins: plugins,
  exclude: "node_modules/**",
  sourceMap: true,
}
