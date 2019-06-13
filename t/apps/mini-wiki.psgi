#!/usr/bin/env perl
use 5.18.2;
use utf8;
use strictures;
use FindBin;
use lib "$FindBin::Bin/../lib";
use MiniWiki;

MiniWiki->to_app;

__DATA__

=pod

=encoding utf8

=head1 Synopsis

 plackup -Ilib -It/lib t/apps/mini-wiki.psgi -R lib,t/apps,t/lib

=cut
