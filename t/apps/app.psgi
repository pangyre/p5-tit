#!/usr/bin/env perl
use 5.14.0;
use utf8;
use strictures;
# use open ":std", ":encoding(utf8)";
use Plack::Builder;
use Path::Tiny;
use File::Spec;

my $dir = path( File::Spec->rel2abs( __FILE__ ) )->parent;

warn "$dir/tit.psgi";

my $tit_survey = do "$dir/tit.psgi";
my $mini_wiki = do "$dir/mini-wiki.psgi";
my $pod_viewer = do "$dir/pod.psgi";

builder {
    mount "/tit" => $tit_survey;
    mount "/mw" => $mini_wiki;
    mount "/pod" => $pod_viewer;
    mount "/" => sub { [ 200, [], [ "OHAI" ] ] };
};


__DATA__

=pod

=encoding utf8

=head1 Name


=head1 Synopsis

=head1 Methods


=head1 Copyright



=cut
