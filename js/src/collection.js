import { refreshTable } from './tables';

class Collection {
  /**
   * Creates an instance of Collection.
   * @param {*} graphObject
   * @param {*} dataObject
   * @memberof Collection
   */
  constructor(graphObject, dataObject) {
    this._graph = graphObject;
    this._data = dataObject || null;
    this._collection = graphObject.collection();
  }

  /**
   * get or set the data object used by the Collection
   *
   * @param {object} dataObject
   * @returns {object} current value of this._data
   * @memberof Collection
   */
  data(dataObject) {
    if (dataObject) {
      this._data = dataObject;
    }
    return this._data;
  }

  /**
   * collectSelectedGraphNodes( dt )
   *
   * adds the nodes currently selected in this._graph to the collection.
   * updates the graph nodes to reflect that they are 'collected'
   * updates the contents of this._data.collection with the selected nodes
   * triggers a refresh of the collection table
   * @memberof Collection
   */
  collectSelectedGraphNodes() {
    const selectedNodes = this._graph.collectSelectedNodes();
    this._collection = this._collection.union(selectedNodes);

    // ensure all node data is populated
    this._collection.forEach((c) => {
      if (!this._data.collection[c.id()]) {
        this._data.collection[c.id()] = this._data.node[c.id()];
      }
    });
    refreshTable('collection');
  }

  /**
   * collectSelectedTableNodes( dt )
   *
   * adds the selected nodes in table dt to the collection
   * updates the graph nodes to reflect that they are 'collected'
   * updates the contents of this._data.collection with the selected nodes
   * triggers a refresh of the collection table
   * @param DataTable dt - table to take the node data from
   * @memberof Collection
   */
  collectSelectedTableNodes(dt) {
    // extract the ids
    dt.rows({ selected: true })
      .data()
      .each((d) => {
        let id = d.id;
        this._data.collection[id] = this._data.node[id];

        let node = this._graph.collectNode(id);
        if (node) {
          this._collection = this._collection.union(node);
        }
      });
    refreshTable('collection');
  }

  /**
   * collectSelectedTableEdges( dt )
   *
   * adds the nodes from the selected edges in table dt to the collection
   * updates the graph nodes to reflect that they are 'collected'
   * updates the contents of this._data.collection with the selected nodes
   * triggers a refresh of the collection table
   * @param DataTable dt - table to take the edge data from
   * @memberof Collection
   */
  collectSelectedTableEdges(dt) {
    dt.rows({ selected: true })
      .data()
      .each((d) => {
        // extract the source and target
        let id_arr = [d.source, d.target];
        id_arr.forEach((id) => {
          this._data.collection[id] = this._data.node[id];
          let node = this._graph.collectNode(id);
          if (node) {
            this._collection = this._collection.union(node);
          }
        });
      });
    refreshTable('collection');
  }

  /**
   * discardSelectedGraphNodes()
   *
   * removes the nodes currently selected in this._graph from the collection.
   * updates the graph nodes to remove the 'collected' state
   * updates the contents of this._data.collection to discard the selected nodes
   * triggers a refresh of the collection table
   * @memberof Collection
   */
  discardSelectedGraphNodes() {
    const selectedNodes = this._graph.discardSelectedNodes();
    this._collection = this._collection.difference(selectedNodes);

    this._collection.forEach((c) => delete this._data.collection[c.id()]);
    refreshTable('collection');
  }

  /**
   * discardSelectedTableNodes()
   *
   * removes the nodes currently selected in dataTable dt from the collection.
   * updates the graph nodes to remove the 'collected' state
   * updates the contents of this._data.collection to discard the selected nodes
   * triggers a refresh of the collection table
   * @param DataTable dt - table to take the edge data from
   * @memberof Collection
   */
  discardSelectedTableNodes(dt) {
    // extract the ids
    dt.rows({ selected: true })
      .data()
      .each((d) => {
        let id = d.id;
        delete this._data.collection[id];
        let node = this._graph.discardNode(id);
        if (node) {
          this._collection = this._collection.difference(node);
        }
      });
    refreshTable('collection');
  }

  /**
   * discardSelectedTableEdges( dt )
   *
   * removes the nodes from the selected edges in table dt from the collection
   * updates the graph nodes to remove the 'collected' state
   * updates the contents of this._data.collection to discard the selected nodes
   * triggers a refresh of the collection table
   * @param DataTable dt - table to take the edge data from
   * @memberof Collection
   */
  discardSelectedTableEdges(dt) {
    dt.rows({ selected: true })
      .data()
      .each((d) => {
        // extract the source and target
        let id_arr = [d.source, d.target];
        id_arr.forEach((id) => {
          delete this._data.collection[id];
          let node = this._graph.discardNode(id);
          if (node) {
            this._collection = this._collection.difference(node);
          }
        });
      });
    refreshTable('collection');
  }
}

export default Collection;
