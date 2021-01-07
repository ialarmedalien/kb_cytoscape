const assert = require("chai").assert,
expect = require("chai").expect,
initCytoscape = require('../src/cytoscape').initCytoscape,
getData = require('./shared-data')

/**
 * Node data
 *
 *
 */


// data.nodeArr = Object.keys(data.nodeEdge).map(el => { return { data: { id: el } } })
// data.edgeArr = Object.values(data.edge).map(el => { return { data: el } } )

function createEmptyGraph() {
  return initCytoscape()
}

function createFilledGraph() {
  const cytoscapeInstance = initCytoscape(),
    data = getData()
  cytoscapeInstance.add({ nodes: data.nodeArr(), edges: data.edgeArr() })
  return cytoscapeInstance
}

function selectNodes(cytoscapeInstance) {
  const to_select = ["a", "d"]
  to_select.forEach((id) => {
    cytoscapeInstance.getElementById(id).select()
  })
  return cytoscapeInstance
}

function httpHelper (options, expectedResponse = errorResponse) {
  const data = request(options, function (error, response, body) {
    it(`has status ${expectedResponse.status}`, function () {
      console.log(data);
      expect(response.statusCode).to.equal(expectedResponse.status);
    });
    it("has the correct content", function () {
      expect(body).to.equal(expectedResponse.body);
    });
  });
}

describe("extensions to cytoscape", function () {
/**
  let server;
  beforeEach(function () {
    server = require("../src/server");
  });
  afterEach(function () {
    server.close();
  });

  describe("file errors", () => {
    const sourceFiles = sharedData.files.invalid;
    for (let fileName in sourceFiles) {
      it("should reject badly-formed input, " + fileName, function (done) {
        const fragmentArray = input.readFile(`${dataDir}${fileName}`);
        expect(textAssembler.assemble(fragmentArray)).to.throw(
          messages.error[sourceFiles[fileName]]
        );
        done();
      });
    }
  });
 */

  cytoscape('core', 'renderGraph', function(data) {
    if ( this.nodes() ) {
      this.nodes().remove()
    }
    if (data && data.nodeArr() && data.edgeArr()) {
      this.add({ nodes: data.nodeArr(), edges: data.edgeArr() })

      if (this.container !== null) {
        // get the current layout
        const layoutValue = $(this.layoutSelector)[0].value || 'null'
        this.setLayout(layoutValue)
      }
    }
    return this
  })

  function countSelectedNodes(graph) {
    let count = 0
    if (graph.nodes().length === 0) {
      return count
    }
    graph.nodes().forEach((el) => {
      if (el.selected()) {
        countSelectedNodes++
      }
    })
    return count
  }

  // cytoscape('core', 'selectAllNodes', function() {
  //   this.nodes().forEach( n => n.select() )
  //   return this
  // })
  describe("selectAllNodes", () => {
    const selectionTest = function(graph) {
      graph.selectAllNodes()
      expect(countSelectedNodes(graph)).to.equal(graph.nodes().length)
    }
    it("should have no effect on an empty graph", () => {
      selectionTest(createEmptyGraph())
    })
    it("should set all nodes in a filled graph to selected", () => {
      selectionTest(createFilledGraph())
    })
    it("should set all nodes in a filled graph with some selected nodes to selected", () => {
      const filledGraph = selectNodes(createFilledGraph())
      selectionTest(filledGraph)
    })
    it("should have no effect on a graph where all nodes are already selected", () => {
      const filledGraph = createFilledGraph()
      filledGraph.nodes().forEach((el) => { el.select() })
      selectionTest(filledGraph)
    })
  })

  describe("deselectAllNodes", () => {
    const deselectionTest = function(graph) {
      graph.deselectAllNodes()
      expect(countSelectedNodes(graph)).to.equal(0)
    }
    it("should have no effect on an empty graph", () => {
      deselectionTest(createEmptyGraph())
    })
    it("should have no effect on a filled graph with no nodes selected", () => {
      deselectionTest(createFilledGraph())
    })
    it("should deselect all nodes in a filled graph with some selected nodes", () => {
      const filledGraph = selectNodes(createFilledGraph())
      deselectionTest(filledGraph)
    })
    it("should deselect all nodes in a filled graph with all nodes selected", () => {
      const filledGraph = createFilledGraph()
      filledGraph.nodes().forEach((el) => { el.select() })
      deselectionTest(filledGraph)
    })
  })

  // cytoscape('core', 'invertNodeSelection', function() {
  //   this.nodes().forEach( e => e.selected() ? e.unselect() : e.select() )
  //   return this
  // })


  // cytoscape('core', 'getSelectedNodes', function() {
  //   return this.filter( el => el.isNode() && el.selected() )
  // })
  describe("getSelectedNodes", () => {
    it("should have no effect on an empty graph", () => {
      const emptyGraph = createEmptyGraph()
      expect(emptyGraph.getSelectedNodes().length).to.equal(0)
    })
    it("should fetch zero nodes from filled graph with no nodes selected", () => {
      const filledGraph = createFilledGraph()
      expect(filledGraph.getSelectedNodes().length).to.equal(0)
    })
    it("should fetch the correct number of nodes from a filled graph with some selected nodes", () => {
      const filledGraph = selectNodes(createFilledGraph())
      expect(filledGraph.getSelectedNodes().length).to.equal(2)
    })
    it("should fetch all nodes in a filled graph with all nodes selected", () => {
      const filledGraph = createFilledGraph()
      filledGraph.nodes().forEach((el) => { el.select() })
      expect(filledGraph.getSelectedNodes().length).to.equal(4)
      // the nodes in the filled graph should be the same as the selected nodes
      expect(eles.same(filledGraph.nodes(), filledGraph.getSelectedNodes())).to.be.true()
    })
  })

  describe("getNeighbourhood", () => {
    it("should do nothing on an empty graph", () => {
      const emptyGraph = createEmptyGraph()
      emptyGraph.getNeighbourhood()
      expect(emptyGraph.getSelectedNodes().length).to.equal(0)
    })
    it("should do nothing on a graph with no nodes selected", () => {
      const filledGraph = createFilledGraph()
      filledGraph.getNeighbourhood()
      expect(filledGraph.getSelectedNodes().length).to.equal(0)
    })
    it("should pick out the neighbours of a node", () => {
      const filledGraph = createFilledGraph()
      filledGraph.getElementById("a").select()
      expect(filledGraph.getSelectedNodes().length).to.equal(1)
      // "a" has edges a_b and a_d
      filledGraph.getNeighbourhood()
      expect(filledGraph.getSelectedNodes().length).to.equal(3)
      expect(filledGraph.getElementById("c").selected()).to.be.false()
    })
    it("should pick out the neighbours of several nodes", () => {
      const filledGraph = createFilledGraph(),
        to_select = ["b", "d"]
      to_select.forEach((el) => {
        filledGraph.getElementById(el).select()
      })
      expect(filledGraph.getSelectedNodes().length).to.equal(2)
      // edges are a_b, a_d, c_d => expect all nodes to be selected
      filledGraph.getNeighbourhood()
      expect(filledGraph.getSelectedNodes().length).to.equal(4)
    })
  })


describe('collectNode', () => {
  it('should do nothing on an empty graph', () => {

  })
  it('should do nothing if the node is not in the graph', () => {

  })
  it('should change the class of the node if the node is present', () => {

  })

})
  // cytoscape('core', 'collectNode', function(id) {

  //   const node = this.getElementById(id)
  //   if ( node ) {
  //     node.addClass('collected')
  //   }
  //   return node
  // })

  cytoscape('core', 'collectSelectedNodes', function() {
    return this.getSelection().addClass('collected')
  })

  cytoscape('core', 'discardNode', function(id) {
    const node = this.getElementById(id)
    if ( node ) {
      node.removeClass('collected')
    }
    return node
  })

  cytoscape('core', 'discardSelectedNodes', function() {
    return this.getSelection().removeClass('collected')
  })

  cytoscape('core', 'setLayout', function(value) {
    const layouts = layoutsAvailable()
    if (layouts[value] || value === 'null') {
      this.layout( layouts[value] ).run()
    }
    return this
  })


});

