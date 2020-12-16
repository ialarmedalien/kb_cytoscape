/*

kb_cytoscape

*/

module kb_cytoscape {

    typedef structure {
        int dry_run;
        string workspace_id;

        list<string> cluster_ids;
        int distance;
        list<string> edge_types;
        list<string> gene_keys;
        list<string> phenotype_keys;
        string search_text;

    } run_kb_cytoscape_input;

    typedef structure {
        string query_params;
        string report_name;
        string report_ref;

    } run_kb_cytoscape_output;

    /*
        run_kb_cytoscape accepts input in the form specified by run_kb_cytoscape_input
        and returns data in the format run_kb_cytoscape_output
    */
    funcdef run_kb_cytoscape(run_kb_cytoscape_input params) returns (run_kb_cytoscape_output output) authentication required;

};