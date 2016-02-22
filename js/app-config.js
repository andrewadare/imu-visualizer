// Configuration file for require.js modules

// Base URL and paths
requirejs.config( {
  baseUrl: 'js/lib',
  paths: {
    app: '../app'
  },

  // Shims for files that define a global object without calling `define`.
  // The key is a file (base)name and `exports` will be the module name.
  shim: {
    three: {
      exports: 'THREE'
    },
    TrackballControls: {
      deps: [ 'three' ],
      exports: 'THREE.TrackballControls'
    }
  }

} );

// Start (asynchronously) loading the following files.
requirejs( [ 'three', 'app/main' ] );
