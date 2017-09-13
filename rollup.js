var rollup = require('rollup');
var coffeescript = require('rollup-plugin-coffee-script')
var cache;

rollup.rollup({
  entry: 'src/event-kit.coffee',
  plugins: [
    coffeescript()
  ],
  cache: cache
}).then(function (bundle) {
  bundle.write({
    moduleName: 'EventKit',
    format: 'umd',
    watch: true,
    dest: 'lib/event-kit.js'
  });
});