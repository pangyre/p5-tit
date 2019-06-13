#!/usr/bin/env perl
use utf8;
use strictures;
use Tit;

# OO style.
get "/" => sub { $tit->response->body(["HERRO"]) };

# Plack response style.
get '¶' => sub { [ 200, [], [ "¶s are fun" ] ] };

get 'any/{unbounded:.+}' => sub {
    $tit->response->body([ "ERR… ", +shift->{unbounded} ]);
};

get 'five/{one}/{two}/{three}/{four}/{five}' => sub {
    my %args = %{ +shift };
    $tit->response->body([ join " ", @args{qw/ one two three four five /} ]);
};

$tit->to_app;

__END__


 plackup -Ilib tit.psgi -R tit.psgi,lib


get "i/♥/utf8" => sub {
    $tit->res->body(["i/♥/utf8 -> ", $req->uri->path]);
};

get "some/route" => sub {
    $tit->res->body(["OHAI ", $req->path_info]);
};

get 'uri/{path:\w[/\w]*\w}' => sub {
    my $arg = shift;
    $tit->res->body([ "URI for with leading slash -> ", $tit->uri_for("/$arg->{path}"),
                      $/,
                      "           URI for without -> ", $tit->uri_for($arg->{path}), ]);
};

# WE NEED TO EXPLICITY BLOCK THIS I GUESS…
get "multiple/args/{arg1}/{arg2}" => sub {
    my $var = shift;
    $tit->res->body(["ERR… ", $req->path_info,
                      $/,
                     "With capture: $var->{arg1}, $var->{arg2}" ]);
};

#get "asdf/{var}" => sub {
#    my $var = shift;
#    $tit->res->body([ "MATCHED uri -> ", $req->path_info,
#                      $/,
#                      "With capture: $var->{var}" ]);
#}, "Xslate"; # Make it case insensisitve…?


get router => sub {
    use YAML;
    my $router = $tit->router;
    $res->body([ "ROUTER ", Dump( $router ) ]);
};

get error => sub {
    use Carp;
    confess "ONOES!!!"
};

Tit->to_app;

__DATA__

=pod

=encoding utf8

=head1 Name

=head1 Synopsis

=head1 Methods

=head1 Copyright

=cut
