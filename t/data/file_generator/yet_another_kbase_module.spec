/*

yet_another_kbase_module

*/

module yet_another_kbase_module {

    typedef structure {
        int five_by_five;
        string system_variable_a;
        int zero_or_one;
        list<string> cluster_ids;
        int distance;
        list<string> edge_types;
        string search_text;
    } run_yet_another_kbase_method_input;

    typedef structure {
        int another_param;
        string report_name;
        string report_ref;
    } run_yet_another_kbase_method_output;

    /*
        run_yet_another_kbase_method accepts input in the form specified by run_yet_another_kbase_method_input
        and returns data in the format run_yet_another_kbase_method_output

    */
    funcdef run_yet_another_kbase_method(run_yet_another_kbase_method_input params) returns (run_yet_another_kbase_method_output output) authentication required;

};
