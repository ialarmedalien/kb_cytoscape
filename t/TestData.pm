package TestData;

use strict;
use warnings;

# data for testing parameter coercion / cleaning up

sub get_data {

    return [{
        # retrieve the full dataset
        query => 'djornl_fetch_all',
        input => {
            cluster_ids       => '',
            # this should be converted to an int
            distance          => undef,
            edge_types        => [],
            gene_keys         => undef,
            phenotype_keys    => "\n\n\n  \t\n",
            search_text       => "\t\t\t\n",
        },
        clean => {
            edge_types      => [],
        }
    },{
        # cluster search
        query => 'djornl_fetch_clusters',
        input => {
            # dupes will be removed
            cluster_ids       => ['cluster:1', 'example:2', 'test_case:3', 'example:2'],
            distance          => 0,
            # these should be deleted
            gene_keys         => undef,
            phenotype_keys    => "",
        },
        clean => {
            cluster_ids     => ['cluster:1', 'example:2', 'test_case:3'],
            distance        => 0,
        },
    },{
        # phenotype search (gene search works the same)
        query => 'djornl_fetch_phenotypes',
        input => {
            # dupes will be removed
            cluster_ids       => undef,
            # this should be converted to an int
            distance          => 1,
            edge_types        => [''],
            # this should be deleted
            gene_keys         => undef,
            # this should be turned into an array
            phenotype_keys    => "key one\n\n\nkey two\nkey three\nkey four\n\nkey two",
            search_text       => undef,
        },
        clean => {
            distance        => 1,
            edge_types      => [],
            phenotype_keys  => ['key one', 'key two', 'key three', 'key four'],
        }
    },{
        # text search with edge filters
        query => 'djornl_search_nodes',
        input => {
            cluster_ids       => '',
            distance          => '1',
            # dupes and empties should be removed
            edge_types        => [
                'phenotype-association_AraGWAS',
                '',
                'pairwise-gene-coexpression_AraNet_v2',
                'domain-co-occurrence_AraNet_v2',
                '',
                "\n\n",
                'phenotype-association_AraGWAS',
                'pairwise-gene-coexpression_AraNet_v2',
                'pairwise-gene-coexpression_AraNet_v2',
                'pairwise-gene-coexpression_AraNet_v2',
                'domain-co-occurrence_AraNet_v2',
            ],
            gene_keys         => " ",
            # no content => remove
            phenotype_keys    => "  \n\n   \n\n    \t \t",
            # valid string!
            search_text       => 'GO:0005155 for the win',
        },
        clean  => {
            distance          => 1,
            edge_types        => [
                'phenotype-association_AraGWAS',
                'pairwise-gene-coexpression_AraNet_v2',
                'domain-co-occurrence_AraNet_v2',
            ],
            search_text     => 'GO:0005155 for the win',
        }
    }];
}

1;