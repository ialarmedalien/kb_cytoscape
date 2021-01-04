import $ from 'jquery';
import cytoscape from 'cytoscape';
import layoutsAvailable from './cytoscapeLayouts';
import kbCytoscape from './kbCytoscape';
// import popper from 'cytoscape-popper';

/**
 * style data for a cytoscape instance
 *
 * @returns {object[]} styleData
 */
function defaultStyle() {
  return [
    {
      selector: 'node',
      style: {
        width: 10,
        height: 10,
        shape: 'ellipse', // (ellipse/rectangle/round-diamond),
        'background-color': '#4682b4',
      },
    },
    {
      selector: 'node.collected',
      style: {
        'border-width': 4,
        width: 14,
        height: 14,
        'border-style': 'solid',
        'border-color': '#264662',
        'border-opacity': 1,
      },
    },
    {
      selector: 'node:selected',
      style: {
        'background-color': '#e77943',
        //         'label': 'data(id)'
      },
    },
    {
      selector: 'node.phenotype',
      style: {
        width: 50,
        height: 50,
        shape: 'round-diamond',
      },
    },
    {
      selector: 'edge',
      style: {
        width: 1,
        'line-color': '#ccc',
      },
    },
  ];
}

/**
 * generate the configuration for a cytoscape instance. If provided with a containerID, the config
 * will include style, layout, and container data; otherwise it will be assumed to be headless.
 *
 * @param {string} containerID (optional)
 * @returns {object} config - cytoscape configuration object
 */
function cytoscapeConfig(containerID) {
  let config = {
    elements: {
      nodes: [],
      edges: [],
    },
  };

  if (containerID) {
    // container to render in
    config.container = document.getElementById(containerID + '--graph');
    config.style = defaultStyle();
    config.layout = 'null';

    // check the current state of the controls
    const layout_value = $(`#${containerID}--controls select[name=layout]`).length
        ? $(`#${containerID}--controls select[name=layout]`)[0].value || 'random'
        : 'random',
      layouts = layoutsAvailable(),
      radioControls = [
        'userZoomingEnabled',
        'userPanningEnabled',
        'boxSelectionEnabled',
        'selectionType',
      ];

    config.layout = layouts[layout_value];

    radioControls.forEach((r) => {
      let val = $('input[name=' + r + ']:checked').val();
      if (val === '0') {
        val = 0;
      }
      config[r] = val;
    });
  } else {
    config.headless = true;
  }

  return config;
}

/**
 * creates a cytoscape instance using cytoscapeConfig, with some extra functionality added
 *
 * @param {string} containerID (optional)
 * @returns {cytoscape} cytoscapeInstance - cytoscape instance
 */
function initCytoscape(containerID) {
  cytoscape.use(kbCytoscape);
  const config = cytoscapeConfig(containerID),
    cytoscapeInstance = cytoscape(config);

  if (containerID) {
    cytoscapeInstance.layoutSelector = `#${containerID}--controls select[name=layout]`;
  }

  return cytoscapeInstance;
}

export { initCytoscape };
