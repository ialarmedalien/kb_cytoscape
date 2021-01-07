#!/usr/bin/env perl

use strict;
use warnings;
use Bio::KBase::FileGenerator;

my $file_generator = Bio::KBase::FileGenerator->new;
$file_generator->generate_files;

print "Finished generating files!\n";

exit 0;
