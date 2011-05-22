#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Algorithm::NaiveBayes;

use lib qw(lib blib/lib blib/arch);
use ToyBox::XS::NaiveBayes;

my $nb = ToyBox::XS::NaiveBayes->new();
#my $nb = Algorithm::NaiveBayes->new();

$nb->add_instance(attributes => {a => 2, b => 3}, label => 'positive');

my $attributes = {c => 1, d => 4};
my $label = 'negative';
$nb->add_instance(attributes => $attributes, label => $label);

$nb->train(alpha => 1.0);

my $result = $nb->predict(attributes => {a => 2, b => 3});
print Dumper($result);

$attributes = {a => 1, b => 1, c => 1, d => 1};
$result = $nb->predict(attributes => $attributes);
print Dumper($result);
