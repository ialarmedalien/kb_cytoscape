import $ from 'jquery';
import dt from 'datatables.net-bs';
import buttons from 'datatables.net-buttons';
import buttons_bs from 'datatables.net-buttons-bs';
import columnVisibility from 'datatables.net-buttons/js/buttons.colVis.js';
import buttonsHtml5 from 'datatables.net-buttons/js/buttons.html5.js';
import scroller from 'datatables.net-scroller-bs';
import searchPanes from 'datatables.net-searchpanes-bs';
import select from 'datatables.net-select-bs';
// import loadMetadata from './data-config'

window.jQuery = window.$ = $;
dt(window, $);
buttons(window, $);
buttons_bs(window, $);
columnVisibility(window, $);
buttonsHtml5(window, $);
scroller(window, $);
searchPanes(window, $);
select(window, $);

function loadMetadata() {
  return {
    djornl_node: {
      user_notes: { title: 'User Notes', type: 'string', examples: ['flowering time related'] },
      go_terms: {
        type: 'array',
        uniqueItems: true,
        items: { $ref: '#/definitions/go_term' },
        definitions: {
          go_term: {
            examples: ['GO:0003700', 'GO:0005515'],
            type: 'string',
            format: 'regex',
            pattern: '^GO:\\d{7}$',
          },
        },
        title: 'GO term IDs',
      },
      mapman_name: {
        examples: ['.RNA biosynthesis.transcriptional regulation.transcription factor (NAC)'],
        type: 'string',
        title: 'Mapman name',
      },
      tair_computational_description: {
        title: 'TAIR computational description',
        type: 'string',
        examples: ['NAC domain containing protein 1;(source:Araport11)'],
      },
      transcript: { title: 'Transcript', type: 'string', examples: ['AT1G01010.1'] },
      pheno_ref: {
        title: 'Phenotype reference',
        type: 'string',
        examples: ['Atwell et. al, Nature 2010'],
      },
      clusters: {
        items: { $ref: '#/definitions/cluster_id' },
        description: 'Clusters to which the node has been assigned',
        title: 'Clusters',
        definitions: {
          cluster_id: {
            format: 'regex',
            pattern: '^\\w+:\\d+$',
            examples: ['markov_i2:1', 'markov_i4:5', 'markov_i6:3'],
            type: 'string',
          },
        },
        uniqueItems: true,
        type: 'array',
        examples: [['markov_i2:1', 'markov_i4:5'], ['markov_i6:3']],
      },
      tair_curator_summary: {
        title: 'TAIR curator summary',
        examples: [
          'Encodes a plasma membrane-localized amino acid transporter likely involved in amino acid export in the developing seed.',
        ],
        type: 'string',
      },
      gene_symbol: { examples: ['NTL10'], type: 'string', title: 'Gene symbol' },
      gene_full_name: {
        examples: ['NAC domain containing protein 1'],
        type: 'string',
        title: 'Gene full name',
      },
      pheno_description: {
        type: 'string',
        examples: [
          'Arsenic concentrations in leaves, grown in soil. Elemental analysis was performed with an ICP-MS (PerkinElmer). Sample normalized to calculated weights as described in Baxter et al., 2008',
        ],
        title: 'Phenotype description',
      },
      _key: { title: 'Key', type: 'string', examples: ['AT1G01010', 'As2'] },
      gene_model_type: { type: 'string', examples: ['protein_coding'], title: 'Gene model type' },
      node_type: {
        name: 'node_type',
        examples: ['gene', 'phenotype'],
        oneOf: [
          { const: 'gene', title: 'Gene' },
          { title: 'Phenotype', const: 'pheno' },
        ],
        type: 'string',
        title: 'Node Type',
        $schema: 'http://json-schema.org/draft-07/schema#',
        description: 'Node types in Dan Jacobson Exascale dataset',
      },
      mapman_bin: { title: 'Mapman bin', examples: ['15.5.17'], type: 'string' },
      pheno_aragwas_id: {
        title: 'AraGWAS ID',
        type: 'string',
        examples: ['10.21958/phenotype:67'],
      },
      mapman_description: {
        title: 'Mapman description',
        type: 'string',
        examples: [
          'transcription factor (NAC) (original description: pep chromosome:TAIR10:1:3631:5899:1 gene:AT1G01010 transcript:AT1G01010.1 gene_biotype:protein_coding transcript_biotype:protein_coding gene_symbol:NAC001 description:NAC domain-containing protein 1 [Source:UniProtKB/Swiss-Prot;Acc:Q0WV96])',
        ],
      },
      go_description: {
        type: 'string',
        examples: ['DNA-binding transcription factor activity'],
        title: 'GO descriptions',
      },
      tair_short_description: {
        type: 'string',
        examples: ['NAC domain containing protein 1'],
        title: 'TAIR short description',
      },
      pheno_pto_description: {
        title: 'PTO description',
        description: 'Plant Trait Ontology description',
        examples: [
          'A mineral and ion content related trait (TO:0000465) which is the concentration of arsenic (CHEBI:22632) in some plant structure (PO:0009011). [GR:Karthik]',
        ],
        type: 'string',
      },
      pheno_pto_name: {
        examples: ['arsenic concentration'],
        type: 'string',
        title: 'PTO name',
        description: 'Plant Trait Ontology name',
      },
    },
    djornl_edge: {
      _key: { type: 'string', pattern: '^(\\S+__){3}(\\S+)$', format: 'regex', title: 'Key' },
      _from: { type: 'string', title: 'Gene ID' },
      edge_type: {
        description: 'Edge types in Dan Jacobson Arabidopsis Exascale dataset',
        title: 'Edge Type',
        $schema: 'http://json-schema.org/draft-07/schema#',
        oneOf: [
          {
            description:
              'GWAS associations produced by analyzing a subset of phenotypes and SNPs in the Arabidopsis 1001 Genomes database. Edge values are significant association scores after FDR correction.',
            title: 'AraGWAS phenotype associations',
            const: 'phenotype-association_AraGWAS',
          },
          {
            const: 'pairwise-gene-coexpression_AraNet_v2',
            description:
              'A subset of pairwise gene coexpression values from the Arabidopsis AraNetv2 database. The LLS scores that serve as edge values were calculated from Pearson correlation coefficients to normalize the data for comparison across studies and different types of data layers (Lee et al, 2015).',
            title: 'AraNetv2 pairwise gene coexpression',
          },
          {
            description:
              'A layer of protein domain co-occurrence values from the Arabidopsis AraNetv2 database. The LLS scores that serve as edge values were calculated from weighted mutual information scores to normalize the data for comparison across studies and different types of data layers (Lee et al, 2015).',
            title: 'AraNetv2 domain co-occurrence',
            const: 'domain-co-occurrence_AraNet_v2',
          },
          {
            const: 'protein-protein-interaction_high-throughput_AraNet_v2',
            description:
              'Log likelihood score. A layer of protein-protein interaction values derived from four high-throughput PPI screening experiments; from the Arabidopsis AraNetv2 database. The LLS scores that serve as edge values were calculated to normalize the data for comparison across studies and different types of data layers (Lee et al, 2015).',
            title: 'AraNetv2 high-throughput protein-protein interaction',
          },
          {
            const: 'protein-protein-interaction_literature-curation_AraNet_v2',
            title: 'AraNetv2 literature-curated protein-protein interaction',
            description:
              'A layer of protein-protein interaction values from literature-curated small- to medium-scale experimental data; from the Arabidopsis AraNetv2 database. The LLS scores that serve as edge values were calculated to normalize the data for comparison across studies and different types of data layers (Lee et al, 2015).',
          },
        ],
        type: 'string',
        name: 'edge_type',
      },
      score: { title: 'Edge Score (Weight)', type: 'number' },
      _to: { type: 'string', title: 'Gene or Phenotype ID' },
    },
  };
}

/**
 * given a column name, supplies the appropriate column header
 *
 * @param {string} colName
 * @returns {string} entitledNames[colName] or colName if it does not exist
 */
function entitle(colName) {
  const metadata = loadMetadata();

  if (metadata[colName]) {
    return metadata[colName];
  }

  const entitledNames = {
    source: 'Source',
    target: 'Target',
    type: 'Type',
    score: 'Score',
    id: 'ID',
    node_type: 'Node type',
    edges: 'Edges',
    transcript: 'Transcript',
    gene_symbol: 'Gene symbol',
    gene_full_name: 'Gene full name',
    gene_model_type: 'Gene model type',
    cluster_i2: 'Cluster I2',
    cluster_i4: 'Cluster I4',
    cluster_i6: 'Cluster I6',
    tair_computational_desc: 'TAIR computational description',
    tair_curator_summary: 'TAIR curator summary',
    tair_short_desc: 'TAIR short description',
    go_terms: 'GO terms',
    go_desc: 'GO description',
    mapman_bin: 'Mapman bin',
    mapman_name: 'Mapman name',
    mapman_desc: 'Mapman description',
    pheno_aragwas_id: 'Pheno AraGWAS ID',
    pheno_scoring: 'Pheno description 1',
    pheno_pto_name: 'Pheno description 2',
    pheno_pto_desc: 'Pheno description 3',
    pheno_ref: 'Pheno ref',
    user_notes: 'User notes',
  };

  return entitledNames[colName] || colName;
}

/**
 * get the button configuration for the given button type
 *
 * @param {string} type
 * @returns {object[]} array containing the button configuration for the button or group of buttons
 */
function buttonConfig(type) {
  const buttonArr = {
    download: [
      {
        text: 'Downloads',
        className: 'disabled',
        enabled: false,
      },
      {
        extend: 'csv',
        text: 'CSV',
        extension: '.csv',
      },
      {
        extend: 'csv',
        text: 'TSV',
        fieldSeparator: '\t',
        extension: '.tsv',
      },
      {
        text: 'JSON',
        // action: function (e, dt, button, config) {
        action: function () {
          $.fn.dataTable.fileSave(
            new Blob([JSON.stringify(dt.buttons.exportData())]),
            'Export.json'
          );
        },
      },
    ],
    nodeCollect: [
      {
        text: 'Collect...',
        className: 'disabled',
        enabled: false,
      },
      {
        name: 'addToCollection',
        text: 'Add selected nodes',
        action: function (e, _dt) {
          return window.kbase.collection.collectSelectedTableNodes(_dt);
        },
      },
      {
        name: 'removeFromCollection',
        text: 'Remove selected nodes',
        action: function (e, _dt) {
          return window.kbase.collection.discardSelectedTableNodes(_dt);
        },
      },
    ],
    edgeCollect: [
      {
        text: 'Collect...',
        className: 'disabled',
        enabled: false,
      },
      {
        name: 'addToCollection',
        text: 'Add nodes in selected edges',
        action: function (e, _dt) {
          return window.kbase.collection.collectSelectedTableEdges(_dt);
        },
      },
      {
        name: 'removeFromCollection',
        text: 'Remove nodes in selected edges',
        action: function (e, _dt) {
          return window.kbase.collection.discardSelectedTableEdges(_dt);
        },
      },
    ],
    select: [
      {
        text: 'Select...',
        className: 'disabled',
        enabled: false,
      },
      {
        extend: 'selectAll',
        text: 'All',
      },
      {
        extend: 'selectNone',
        text: 'None',
      },
      {
        name: 'selectFilter',
        text: 'Filtered',
        action: function (e, _dt) {
          _dt.rows({ search: 'applied' }).select();
        },
      },
    ],
    colvis: [
      {
        extend: 'colvis',
        columns: ':gt(0)',
      },
    ],
    searchPane: [
      {
        extend: 'searchPanes',
        text: 'Faceted search',
      },
    ],
  };

  return buttonArr[type];
}

/**
 * get the list of columns in a table
 *
 * @param {string} type - table type
 * @returns {array} column list
 */
function columnList(type) {
  // const metadata = loadMetadata();
  //   node_meta = Object.keys(metadata.djornl_node);
  const cols = {
    collection: ['select', 'id', 'node_type', 'transcript', 'gene_symbol'],
    edge: ['select', 'id', 'source', 'target', 'type', 'score'],
    node: [
      'select',
      'id',
      'node_type',
      'transcript',
      'gene_symbol',
      'gene_full_name',
      'edges',
      'view',
    ],
    nodeMetadata: [
      'select',
      'id',
      'node_type',
      'transcript',
      'gene_symbol',
      'gene_full_name',
      'edges',
      'gene_model_type',
      'clusters',
      'tair_computational_desc',
      'tair_curator_summary',
      'tair_short_desc',
      'go_terms',
      'go_desc',
      'mapman_bin',
      'mapman_name',
      'mapman_desc',
      'pheno_aragwas_id',
      'pheno_scoring',
      'pheno_pto_name',
      'pheno_pto_desc',
      'pheno_ref',
      'user_notes',
      'view',
    ],
  };
  return cols[type];
}

/**
 * set up the dataTables configuration for each column in the table
 *
 * @param {string} type
 * @returns {object[]} array of objects with column config information
 */
function columnConfig(type) {
  const columns =
    type === 'collection' || type === 'node' ? columnList('nodeMetadata') : columnList(type);

  let visibleCols;
  // 'node' and 'collection' pages have all the metadata but it is initially hidden
  if (type === 'collection' || type === 'node') {
    visibleCols = columnList(type);
  }

  const predefinedCols = {
    view: {
      className: 'view',
      data: 'id',
      defaultContent: '',
      orderable: false,
      render: (data, _type) => {
        if (_type === 'display') {
          return '<button class="view_button">Show</button>';
        }
        return '';
      },
      searchable: false,
      title: 'Details',
    },
    select: {
      className: 'select-checkbox', // automatically provided by dataTables css
      data: null,
      defaultContent: '',
      orderable: false,
      targets: 0,
      title: 'Select',
    },
  };

  return columns.map((colName) => {
    let rtnObj = predefinedCols[colName]
      ? predefinedCols[colName]
      : {
          data: colName,
          className: colName,
          title: entitle(colName),
          defaultContent: '',
        };

    // hide the extra metadata columns initially
    if ((type === 'collection' || type === 'node') && visibleCols.indexOf(colName) === -1) {
      rtnObj.visible = false;
    }
    // custom renderer for edges column
    if (colName === 'edges') {
      rtnObj['render'] = (data, _type) => {
        if (!data) {
          return;
        }
        if (_type === 'display') {
          return data.join(', ');
        }
        return data;
      };
    }
    return rtnObj;
  });
}

/**
 * get the search pane config for a given table type
 *
 * @param {string} type
 * @returns {object[]} searchPane configuration
 *
 * Not currently in use
 */
function searchPaneConfig(type) {
  const columns = columnList(type);

  // no filtering on ID
  if (type === 'edge') {
    return columns.map((el, i) => (el === 'ID' ? '' : i)).filter((el) => el);
  }

  const nodeFilterCols = [
    'Node type',
    'Edges',
    //       'Transcript',
    //       'Gene symbol',
    //       'Gene full name',
    'Gene model type',
    'clusters',
    //       'TAIR computational desc',
    //       'TAIR curator summary',
    //       'TAIR short desc',
    'GO terms',
    //       'GO descr',
    'Mapman bin',
    //       'Mapman name',
    //       'Mapman desc',
    'Pheno AraGWAS ID',
    //       'Pheno desc1',
    //       'Pheno desc2',
    //       'Pheno desc3',
    //       'Pheno ref',
    //       'User notes',
  ];
  return columns
    .map((el, i) => (nodeFilterCols.indexOf(el) === -1 ? undefined : i))
    .filter((el) => el);
}

/**
 * format data for display in the expandable section of a table row
 * gene and phenotype objects have different pieces of data provided, so only the relevant fields should be displayed
 *
 * @param {object} d - row data
 * @returns {string} HTML string with data formatted according to what it contains
 */
function formatData(d) {
  const propertyList = {
      gene: [
        'gene_model_type',
        'clusters',
        'tair_computational_desc',
        'tair_curator_summary',
        'tair_short_desc',
        'go_terms',
        'go_desc',
        'mapman_bin',
        'mapman_name',
        'mapman_desc',
      ],
      pheno: ['pheno_aragwas_id', 'pheno_scoring', 'pheno_pto_name', 'pheno_pto_desc', 'pheno_ref'],
      all: ['user_notes'],
    },
    objProperties = propertyList[d.node_type].concat(propertyList.all);

  let str = '';
  objProperties.forEach((prop) => {
    let name = entitle(prop);
    if (d[prop]) {
      str += `<dt>${name}</dt><dd>${d[prop]}</dd>`;
    }
  });
  if (str !== '') {
    return `<dl class="something">${str}</dl>`;
  }
  return '<p>No information available</p>';
}

/**
 * compile the table configuration for a given table type (node, edge, or collection)
 *
 * @param {string} type
 * @returns {object} tableConfig, ready to initialise a DataTables table!
 */
function tableConfig(type) {
  if (type === 'collection') {
    return {
      columns: columnConfig(type),
      dom: '<"table-top clearfix"fiB>rt<"table-bottom clearfix"l>',
      scrollY: 500,
      order: [[1, 'desc']],
      scrollCollapse: true,
      scroller: true,
      buttons: buttonConfig('colvis').concat(buttonConfig('download')),
    };
  }

  const buttonArr =
    type === 'edge'
      ? buttonConfig('select').concat(buttonConfig('edgeCollect'))
      : buttonConfig('colvis').concat(buttonConfig('select')).concat(buttonConfig('nodeCollect'));

  return {
    columns: columnConfig(type),
    // l - length changing input control
    // f - filtering input
    // t - The table!
    // i - Table information summary
    // p - pagination control
    // r - processing display element
    dom: '<"table-top clearfix"fiB>rt<"table-bottom clearfix"lp>',
    scrollX: true,
    order: [[1, 'desc']],
    paging: true,
    lengthMenu: [
      [25, 50, 100],
      [25, 50, 100],
    ],
    deferRender: true,
    //     searchPanes: searchPaneConfig(type),
    select: {
      style: 'os',
      selector: 'td:first-child',
    },
    rowId: 'id',
    buttons: buttonArr,
  };
}

export { tableConfig, formatData };
