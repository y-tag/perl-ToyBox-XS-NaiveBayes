package ToyBox::XS::NaiveBayes;

use 5.0080;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('ToyBox::XS::NaiveBayes', $VERSION);

sub add_instance {
    my ($self, %params) = @_;

    die "No params: attributes" unless defined($params{attributes});
    die "No params: label" unless defined($params{label});
    my $attributes = $params{attributes};
    my $label      = $params{label};
    die "attributes is not hash ref"   unless ref($attributes) eq 'HASH';
    die "attributes is empty hash ref" unless keys %$attributes;
    $label = [$label] unless ref($label) eq 'ARRAY';

    my %copy_attr = %$attributes;

    foreach my $l (@$label) {
        $self->xs_add_instance(\%copy_attr, $l);
    }
    1;
}

sub train{
    my ($self, %params) = @_;

    my $alpha = $params{alpha};
    $alpha = 1.0 unless defined($alpha);
    die "alpha is le 0" unless $alpha > 0;

    $self->xs_train($alpha);
    1;
}

sub predict {
    my ($self, %params) = @_;

    die "No params: attributes" unless defined($params{attributes});
    my $attributes = $params{attributes};
    die "attributes is not hash ref"   unless ref($attributes) eq 'HASH';
    die "attributes is empty hash ref" unless keys %$attributes;

    my $result = $self->xs_predict($attributes);

    $result;
}


1;
__END__
=head1 NAME

ToyBox::XS::NaiveBayes - Simple Naive Bayes using Perl XS

=head1 SYNOPSIS

  use ToyBox::XS::NaiveBayes;

  my $nb = ToyBox::XS::NaiveBayes->new();
  
  $nb->add_instance(
      attributes => {a => 2, b => 3},
      label => 'positive'
  );
  
  $nb->add_instance(
      attributes => {c => 3, d => 1},
      label => 'negative'
  );
  
  $nb->train(alpha => 1.0);
  
  my $probs = $nb->predict(
                  attributes => {a => 1, b => 1, d => 1, e =>1}
              );

=head1 DESCRIPTION

This module implements a simple Naive Bayes using Perl XS.

=head1 AUTHOR

TAGAMI Yukihiro <tagami.yukihiro@gmail.com>

=head1 LICENSE

This library is distributed under the term of the MIT license.

L<http://opensource.org/licenses/mit-license.php>
