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

use strict;
use warnings;

package Bio::EnsEMBL::Variation::DBSQL::VariationFeatureOverlapAdaptor;

use Bio::EnsEMBL::Utils::Exception qw(throw warning);

use base qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);

sub fetch_all_by_Features {
    my ($self, $features) = @_;
    return $self->fetch_all_by_Features_with_constraint($features,'is_somatic = 0');
}

sub fetch_all_somatic_by_Features {
    my ($self, $features) = @_;
    return $self->fetch_all_by_Features_with_constraint($features,'is_somatic = 1');
}

sub fetch_all_by_Features_with_constraint {
    
    my ($self, $features, $constraint) = @_;
    
    my $dbh = $self->dbc->db_handle;
   
    my %feats_by_id = map { ($_->can('stable_id') ? $_->stable_id : $_->_stable_id) => $_ } @$features;
    
    my $id_str = join',', map {"'$_'"} keys %feats_by_id;
    
    my $full_constraint = "feature_stable_id in ( $id_str )";
    $full_constraint .= " AND $constraint" if $constraint;
    
    my $vfos = $self->generic_fetch($full_constraint);
    
    for my $vfo (@$vfos) {
        if ($vfo->{_feature_stable_id}) {
            my $feat_id = delete $vfo->{_feature_stable_id};
            $vfo->{feature} = $feats_by_id{$feat_id};
        }
    }
    
    return $vfos;
}

sub fetch_all_by_VariationFeatures {
    
    my ($self, $vfs) = @_;
    
    my $dbh = $self->dbc->db_handle;
   
    my %vfs_by_id = map { $_->stable_id => $_ } @$vfs;
    
    my $id_str = join',', map {"'$_'"} keys %vfs_by_id;
    
    my $full_constraint = "variation_feature_id in ( $id_str )";
    
    my $vfos = $self->generic_fetch($full_constraint);
    
    for my $vfo (@$vfos) {
        if ($vfo->{_variation_feature_id}) {
            my $vf_id = delete $vfo->{_variation_feature_id};
            $vfo->{variation_feature} = $vfs_by_id{$vf_id};
        }
    }
    
    return $vfos;
}

sub ensembl_class_for_SO_term {
    my ($self, $SO_term) = @_;
    return $self->_feature_types->{$SO_term}->{ensembl_feature_type};
}

sub ensembl_biotype_for_SO_term {
    my ($self, $SO_term) = @_;
    return $self->_feature_types->{$SO_term}->{ensembl_biotype};
}

sub ensembl_variant_class_for_SO_term {
    my ($self, $SO_term) = @_;
    return $self->_feature_types->{$SO_term}->{ensembl_variant_type};
}

sub SO_term_for_ensembl_feature {
    my ($self, $feature) = @_;
    return $self->_feature_types->{ref $feature}->{SO_term};
}

sub _feature_types {
    my $self = shift;
    
    unless ($self->{_feature_types}) {
        my $dbh = $self->dbc->db_handle;
        
        my $sth = $dbh->prepare_cached(qq{
            SELECT  feature_so_term, ensembl_feature_type, ensembl_biotype, ensembl_variant_type
            FROM    feature_types
        });
        
        $sth->execute;
        
        my $mapping = {};
        
        while (my ($SO_term, $ens_type, $ens_biotype, $var_type) = $sth->fetchrow_array) {
            $mapping->{$SO_term} = {
                ensembl_feature_type    => $ens_type,
                ensembl_biotype         => $ens_biotype,
                ensembl_variant_type    => $var_type,
            };
            
            $mapping->{$ens_type} = {
                SO_term => $SO_term,
            };
        }
        
        $self->{_feature_types} = $mapping;
    }
    
    return $self->{_feature_types};
}

sub _overlap_consequences {
    my $self = shift;
    
    unless ($self->{_overlap_consequences}) {
        my $cons = $self->db->get_OverlapConsequenceAdaptor->fetch_all;
        $self->{_overlap_consequences} = { map { $_->SO_id => $_ } @$cons };
    }
    
    return $self->{_overlap_consequences};
}

1;