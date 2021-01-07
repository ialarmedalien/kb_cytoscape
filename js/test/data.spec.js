const assert = require("chai").assert,
expect = require("chai").expect


import { dataObject, loadDataset } from '../src/data'
import { expect } from 'chai'
import data from './shared-data'
// import 'chai/register-should'

/**
 * parse a data dump and extract the useful data, separated into nodes and edges.
 * only edges from datasets
 *
 * @param {object} allData
 * @param {string[]} datasets - the datasets to load
 * @returns {object} data - parsed, organised data
 */
// function extractData(allData, datasets) {

//   const inputData = allData.pop()

//   // keys are assocs, genes, phenotypes
//   let data = {
//     node: {},
//     edge: {},
//     nodeEdge: {},
//   }

//   const nodeType = ['from', 'to']
//   inputData['assocs'].forEach(d => {
//     if ( datasets.indexOf(d.type) !== -1) {
//       data.edge[d.id] = {
//         id: d.id,
//         source: d.from,
//         target: d.to,
//         type: d.type,
//         score: d.score,
//         data_type: 'edge',
//       }

//       nodeType.forEach( n => {
//         data.nodeEdge[d[n]]
//         ? data.nodeEdge[d[n]].push(d.id)
//         : data.nodeEdge[d[n]] = [d.id]
//       })
//     }
//   })

//   // pheno and gene data
//   const data_types = ['genes', 'phenotypes']
//   data_types.forEach( type => {
//     inputData[ type ].forEach( d => {
//       // only add to node data if the node is used by an edge
//       if (data.nodeEdge[d.id]) {
//         d.data_type = 'node'
//         d.edge = data.nodeEdge[d.id]
//         data.node[d.id] = d

//         // make sure the GO terms are presented reasonably
//         if (d.go_terms && d.go_terms.length > 0) {
//           d.go_ids = d.go_terms
//           d.go_terms = d.go_ids.sort().join(", ")
//         }
//       }
//     })
//   })

//   // ensure that all nodes are present in nodeData
//   Object.keys(data.nodeEdge).forEach( n => {
//     if (! data.node[n]) {
//       console.error('no node data for ' + n)
//     }
//   })
//   return data
// }



/**
 * Populate tables and window data store with data
 *
 * @param {object} data
 * @param {string[]} datasets
function renderData(data, datasets) {

  refreshTable()
  // set the collection data
  window.kbase.collection.data(data)

}

describe("data rendering", function() {



})

describe("data extraction", function() {
  it("should be able to cope with empty input", () => {


  })
  it("should cope with malformed input", () => {

  })

  it("should be able to parse input data", () => {
    const extractedData = extractData(input, inputDatasets)

  })
})
*/
describe("dataObject", function() {
  it("can cope with empty nodes", () => {
    const dataO = dataObject()
    expect(dataO.nodeArr()).to.equal([])
    expect(dataO.edgeArr()).to.equal([])
  })

  // node: {},
  // edge: {},
  // nodeEdge: {},
  // collection: {},
  // nodeArr: function() {
  //   return Object.keys(this.nodeEdge).map(el => { return { data: { id: el } } })
  // },
  // edgeArr: function() {
  //   return Object.values(this.edge).map(el => { return { data: el } } )
  // },
it("returns the correct result with data in it", () => {
    const dataO = dataObject(),
    nodes = data.nodes,
    edges = data.edges

    for (let n of nodes) {
      dataO.node[n.id] = n
    }
    for (let e of edges) {
      dataO.edge[e.id] = e
    }

    expect(dataO.nodeArr()).sort( (a, b) => a.data.id - b.data.id )).to.equal([
      {
        data: { id: "a" }
      },
      {
        data: { id: "b" }
      },
      {
        data: { id: "c" }
      },
      {
        data: { id: "d" }
      },
    ])
    // output is not sorted, so ensure that we sort before comparing them
    expect(dataO.edgeArr().sort( (a, b) => a.data.id - b.data.id )).to.equal([
      {
        data: {
          id: "a_b",
          source: "a",
          target: "b",
        },
      },
      {
        data: {
          id: "a_d",
          source: "a",
          target: "d",
        },
      },
      {
        data: {
          id: "c_d",
          source: "c",
          target: "d",
        },
      },
    ])
  })
})
