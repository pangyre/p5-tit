#!/usr/bin/env perl
use utf8;
use strictures;
use Tit;
use Pod::Simple::Text;

add_view HTML => "Xslate";

get "/{module:.+}" => sub {
    my $module = +shift->{module};
    my $pod_parser = Pod::Simple::Text->new;
    $pod_parser->output_string(\my $text);
    # This will prefer blib over lib… :|
    my $path = `perldoc -l $module` || `perldoc -l Tit`;
    $pod_parser->parse_file( `perldoc -l $path` );
    # [ 200, [], [ $text ] ];
    $tit->response->body([ $text ]);
};

$tit->to_app;

__END__

=pod

=encoding utf8

=head1 Name

pod.psgi – minimal POD viewer.

=head1 Synopsis

 plackup -Ilib -r t/apps/pod.psgi

=head1 To Do

Apply content negotiation to give plain/text or text/html(?).

=cut
