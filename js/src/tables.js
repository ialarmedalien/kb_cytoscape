import $ from 'jquery';
import dt from 'datatables.net-bs';
import buttons from 'datatables.net-buttons';
import buttons_bs from 'datatables.net-buttons-bs';
import columnVisibility from 'datatables.net-buttons/js/buttons.colVis.js';
import buttonsHtml5 from 'datatables.net-buttons/js/buttons.html5.js';
import scroller from 'datatables.net-scroller-bs';
import searchPanes from 'datatables.net-searchpanes-bs';
import select from 'datatables.net-select-bs';
import { tableConfig, formatData } from './table-config';

window.jQuery = window.$ = $;
dt(window, $);
buttons(window, $);
buttons_bs(window, $);
columnVisibility(window, $);
buttonsHtml5(window, $);
scroller(window, $);
searchPanes(window, $);
select(window, $);

/**
 * refreshTable(tableID)
 *
 * populate table(s) with the data in the corresponding window.kbase.data[tableID] data store
 * if a tableID is supplied, only refresh the data in that table; otherwise, refresh all tables
 * also updates the table row count in the `${tableID}_count` element
 *
 * @param {string} tableID (optional)
 * @returns - nothing
 */
function refreshTable(tableID) {
  Object.keys(window.kbase.tableIx).forEach((k) => {
    if (!tableID || k === tableID) {
      let thisTable = window.kbase.tableIx[k].DataTable();
      thisTable.clear().rows.add(Object.values(window.kbase.data[k])).draw();
      // update the count of number of rows in the table
      $(`#${k}_count`).text(Object.values(window.kbase.data[k]).length);
      thisTable.order([1, 'asc']).draw();
      thisTable.columns.adjust().draw();
    }
  });
}

/**
 * @function addButtonListener
 * add a listener to the table body to detect clicks on the details button
 * when these events are detected, details of the row data will be displayed
 *
 * @param {string} tableID
 * @returns - nothing, but the table 'tbody' DOM element will have an event listener attached
 */
function addButtonListener(tableID) {
  // Show / Hide metadata details
  const table = $(`#${tableID}_table`).DataTable();
  $(`#${tableID}_table tbody`)
    .off()
    .on('click', '.view_button', (e) => {
      let tr = $(e.target).closest('tr'),
        row = table.row(tr);
      if (row.child.isShown()) {
        // This row is already open - close it
        row.child.hide();
        tr.removeClass('shown');
        $(e.target).text('Show');
      } else {
        // Open this row
        const str = formatData(row.data());
        row.child(str).show();
        tr.addClass('shown');
        $(e.target).text('Hide');
      }
    });
}

/**
 * initialise the 'edge', 'node', and 'collection' tables with the table config generated in table-config.js
 * sets the table data to an empty array
 *
 * @returns {object} tableIx, in the form { tableKey: $jQueryTableDOMElement }
 */
function initTables() {
  const tableIDs = ['edge', 'node', 'collection'];
  let tableIx = {};

  tableIDs.forEach((tableID) => {
    let config = tableConfig(tableID);
    config.data = [];
    // initialise the table
    $(`#${tableID}_table`).DataTable(config);
    addButtonListener(tableID);
    tableIx[tableID] = $(`#${tableID}_table`);
  });

  window.kbase.tableIx = tableIx;
  return tableIx;
}

export { initTables, refreshTable };
