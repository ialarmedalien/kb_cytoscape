import resolve from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import pkg from './package.json';

export default [
  // browser-friendly UMD build
  {
    input: 'src/main.js',
    output: {
      name: 'initKbCytoscape',
      file: pkg.browser,
      format: 'umd',
      globals: {
        'jquery': '$',
//         'datatables.net-bs': '$.DataTable',
//         'datatables.net-buttons-bs': '$.DataTable',
//         'datatables.net-scroller-bs': '$.DataTable',
//         'datatables.net-searchpanes-bs': '$.DataTable',
//         'datatables.net-select-bs': '$.DataTable',
      },
    },
    plugins: [
      resolve(), // ensure Rollup can find node_modules
      commonjs() // ensure Rollup can convert node_modules to ES module format
    ],
    external: [
      'jquery',
//       'datatables.net-bs',
//       'datatables.net-buttons-bs',
//       'datatables.net-scroller-bs',
//       'datatables.net-searchpanes-bs',
//       'datatables.net-select-bs',
    ]
  },

  // CommonJS (for Node) and ES module (for bundlers) build.
  // (We could have three entries in the configuration array
  // instead of two, but it's quicker to generate multiple
  // builds from a single configuration where possible, using
  // an array for the `output` option, where we can specify
  // `file` and `format` for each target)
//   {
//     input: 'src/main.js',
//     external: [
//       'crossfilter2',
//       'cytoscape',
//       'datatables.net-bs',
//       'datatables.net-buttons-bs',
//       'datatables.net-scroller-bs',
//       'datatables.net-searchpanes-bs',
//       'datatables.net-select-bs',
//       'd3-fetch',
//       'd3-dsv',
//       'jquery',
//     ],
//     output: [
// //       { file: pkg.main, format: 'cjs' },
//       { file: pkg.module, format: 'es' }
//     ]
//   }
];
