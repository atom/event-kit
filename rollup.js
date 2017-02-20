var rollup = require( 'rollup' );
var coffeescript = require('rollup-plugin-coffee-script')
var cache;

rollup.rollup({
  entry: 'src/event-kit.coffee',
  plugins: [
      coffeescript()
  ],
  cache: cache
}).then( function ( bundle ) {
  bundle.write({
    format: 'iife',
    watch: true,
    dest: 'lib/browser/event-kit.js'
  });
});
