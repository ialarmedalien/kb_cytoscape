import * as d3 from 'd3-fetch'; // d3.text, d3.json
import { refreshTable } from './tables';
import { message } from './message';

/**
 * object that stores node and edge data, with a couple of utility functions
 *
 * @returns {object} dataObject
 */
function dataObject() {
  return {
    node: {},
    edge: {},
    nodeEdge: {},
    collection: {},
    nodeArr: function () {
      return Object.keys(this.nodeEdge).map((el) => {
        return { data: { id: el } };
      });
    },
    edgeArr: function () {
      return Object.values(this.edge).map((el) => {
        return { data: el };
      });
    },
  };
}

/**
 * parse a data dump and extract the useful data, separated into nodes and edges.
 * only edges from datasets
 *
 * @param {object} allData
 * @param {string[]} datasets - the datasets to load
 * @returns {object} data - parsed, organised data
 */
function extractData(allData, datasets) {
  const inputData = allData.pop();

  // keys are assocs, genes, phenotypes

  let data = dataObject();

  const nodeType = ['from', 'to'];

  // add all edges
  inputData['assocs'].forEach((d) => {
    if (datasets.indexOf(d.type) !== -1) {
      data.edge[d.id] = {
        id: d.id,
        source: d._from,
        target: d._to,
        type: d.type,
        score: d.score,
        data_type: 'edge',
      };

      nodeType.forEach((n) => {
        data.nodeEdge[d[n]] ? data.nodeEdge[d[n]].push(d.id) : (data.nodeEdge[d[n]] = [d.id]);
      });
    }
  });

  // add node (pheno and gene) data
  const dataTypes = ['genes', 'phenotypes'];
  dataTypes.forEach((type) => {
    inputData[type].forEach((d) => {
      // only add to node data if the node is used by an edge
      if (data.nodeEdge[d.id]) {
        d.data_type = 'node';
        d.edge = data.nodeEdge[d.id];
        data.node[d.id] = d;

        // make sure the GO terms are presented reasonably
        if (d.go_terms && d.go_terms.length > 0) {
          d.go_ids = d.go_terms;
          d.go_terms = d.go_ids.sort().join(', ');
        }
      }
    });
  });

  // ensure that all nodes used in the edges are present in data.node
  Object.keys(data.nodeEdge).forEach((n) => {
    if (!data.node[n]) {
      console.error(`no node data for ${n}`);
    }
  });
  return data;
}

/**
 * Populate tables and window data store with data
 *
 * @param {object} data
 * @param {string[]} datasets
 */
function renderData(data, datasets) {
  refreshTable();

  console.log('Found ' + data.nodeArr().length + ' nodes and ' + data.edgeArr().length + ' edges');

  // set the collection data
  window.kbase.collection.data(data);

  // let xf = crossfilter(Object.values(data.edge))
  // window.kbase.xfDim['type'] = xf.dimension(d => d.type)
  // apply filters
  // let filteredEdges = data.edge.filter(f => datasets.indexOf(f.type) !== -1)

  // xfDim[tableSetup[k]['xf']]
  //   .group()
  //   .top(Infinity)
  //   .filter(d => d.value > 0)
}

/**
 * load one or more datasets by AJAX from a JSON file, extract and process the data,
 * and use it to populate the display
 *
 * @param {string[]} datasets - array of edge type names
 */
function loadDataset(datasets) {
  // datasets is an array of edge type names
  if (datasets.length < 1) {
    alert(message('load_more_dataset'));
    return;
  }

  // d3.json, d3.text
  let dataFiles = [
    [
      '/static/cytoscape/data/data_config.json',
      'json',
      '/static/cytoscape/data/djornl_dataset.json',
      'json',
    ],
  ];
  Promise.all(dataFiles.map((v) => d3[v[1]](v[0]))).then((allFileData) => {
    const data = extractData(allFileData, datasets);
    window.kbase.data = data;
    renderData(data, datasets);
  });
}

/**
function queryEndpoint(queryType, queryParams) {

  const db_endpoint = 'https://ci.kbase.us/services/relation_engine_api/api/v1/query_results?stored_query=',
  queries = {
    djornl_cluster_neighbors: {
      cluster_name: "cluster_I2",
      cluster_id: "Cluster12",
    },
    djornl_fetch_genes: {
        keys: ["AT1G01010"]
    },
    djornl_fetch_phenotypes: {
        keys: ["As2"],
    },

    djornl_gene_neighbors: {
        gene_key: "AT1G01010",
    },
    djornl_search_genes: {
      search_text: 'GO:0005515',
    },
  }

  if (!queries[queryType]) {
    alert(message('invalid_query'))
    return
  }
  if (!queryString.length) {
    alert(message('no_query_string'))
  }
  my %headers = (
    'Authorization' => 'token ' . $token,
    'Content-Type'  => 'application/json',
);

Object.keys( queries ).sort().forEach( (query) => {



})
for let query in queries
for my $query ( sort keys %args ) {
    my $response = $ua->post(
      $db_endpoint . $query,
      %headers,
      Content => encode_json( $args{ $query }),
    );
    ok $response->is_success, "Successful request for $query query";
    say Dumper decode_json( $response->content );
}
};


  const url =

  $.ajax(


  )



}
*/

// function editEntry(id, changes) {
//     uniqueDimension.filter(id); // filter to the item you want to change
//     var selectedEntry = uniqueDimension.top(1)[0]; // get the item
//     _.extend(selectedEntry, changes); // apply changes to it
//     ndx.remove(); // remove all items that pass the current filter (which will just be the item we are changing
//     ndx.add([selectedEntry]); // re-add the item
//     uniqueDimension.filter(null); // clear the filter
//     dc.redrawAll(); // redraw the UI
// }

export { loadDataset, dataObject };
