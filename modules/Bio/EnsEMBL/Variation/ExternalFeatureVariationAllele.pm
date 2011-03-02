=head1 LICENSE

 Copyright (c) 1999-2011 The European Bioinformatics Institute and
 Genome Research Limited.  All rights reserved.

 This software is distributed under a modified Apache license.
 For license details, please see

   http://www.ensembl.org/info/about/code_licence.html

=head1 CONTACT

 Please email comments or questions to the public Ensembl
 developers list at <dev@ensembl.org>.

 Questions may also be sent to the Ensembl help desk at
 <helpdesk@ensembl.org>.

=cut

package Bio::EnsEMBL::Variation::ExternalFeatureVariationAllele;

use strict;
use warnings;

use base qw(Bio::EnsEMBL::Variation::VariationFeatureOverlapAllele);

sub external_feature_variation {
    my $self = shift;
    return $self->variation_feature_overlap;
}

sub external_feature {
    my $self = shift;
    return $self->external_feature_variation->external_feature;
}

1;