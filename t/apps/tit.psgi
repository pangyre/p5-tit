#!/usr/bin/env perl
use utf8;
use strictures;
use Tit;

# OO style.
get "/" => sub { $tit->response->body(["HERRO"]) };

# Plack response style + utf8 paths.
get "/¶" => sub { [ 200, [], [ "¶s are fun" ] ] };
get "/i/♥/utf8" => sub {
    $tit->res->body([ "i/♥/utf8 -> ", $tit->req->uri->path ]);
};

# Capture anything, including what would be path parts.
get "/any/{unbounded:.+}" => sub {
    $tit->response->body([ "ERR… ", +shift->{unbounded} ]);
};

get "/five/{one}/{two}/{three}/{four}/{five}" => sub {
    my %args = %{ +shift };
    $tit->response->body([ join " ", @args{qw/ one two three four five /} ]);
};

get "/router" => sub {
    use YAML;
    my $router = $tit->router;
    $tit->res->body([ "ROUTER ", Dump( $router ) ]);
};

get "/error" => sub {
    use Carp;
    confess "ONOES!!!"
};

Tit->to_app; # $tit->to_app;

__DATA__

=pod

=encoding utf8

=head1 Name

tit.psgi – Various test endpoints and exercises.

=head1 Synopsis

 plackup -Ilib -r t/apps/tit.psgi

=cut
