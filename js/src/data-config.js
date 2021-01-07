function loadMetadata() {
  /* N.b. THIS IS OUT OF DATE! */
  return {
    djornl_node: {
      user_notes: {
        title: 'User Notes',
        type: 'string',
        examples: ['flowering time related'],
      },
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
      transcript: {
        title: 'Transcript',
        type: 'string',
        examples: ['AT1G01010.1'],
      },
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
      gene_symbol: {
        examples: ['NTL10'],
        type: 'string',
        title: 'Gene symbol',
      },
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
      gene_model_type: {
        type: 'string',
        examples: ['protein_coding'],
        title: 'Gene model type',
      },
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
      mapman_bin: {
        title: 'Mapman bin',
        examples: ['15.5.17'],
        type: 'string',
      },
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
      _key: {
        type: 'string',
        pattern: '^(\\S+__){3}(\\S+)$',
        format: 'regex',
        title: 'Key',
      },
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

export default { loadMetadata };
