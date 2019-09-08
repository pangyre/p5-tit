#!/usr/bin/env perl
use utf8;
use 5.12.0;
use strictures;
use Tit;

package TitPod::Plain {
    use Moo; # Just for OO wrap.
    use strictures;
    use Pod::Simple::Text;
    use Carp;
    sub render {
        my ( $self, $tit ) = @_;
        my $module = $tit->request->captures->{module};
        $tit->response->headers([ "Content-Type" => "text/plain; charset=utf8" ]); # No encoding…?
        my $pod_parser = Pod::Simple::Text->new;
        $pod_parser->output_string(\my $text);
        # This will prefer blib over lib… :|
        my $path = `perldoc -l $module` || `perldoc -l Tit`;
        # No error/404 feedback…
        $pod_parser->parse_file( `perldoc -l $path` );
        # [ 200, [], [ $text ] ];
        $tit->response->body([ $text ]);
    }

    1;
};

# push @INC, "TitPod::Plain";

# add_view Plain => "Plain";
add_view POD => "+TitPod::Plain";

get '/{module:[\w:]+}' => sub {
    my $module = +shift->{module};
    my $pod_parser = Pod::Simple::Text->new;
    $pod_parser->output_string(\my $text);
    # This will prefer blib over lib… :|
    my $path = `perldoc -l $module` || `perldoc -l Tit`;
    # No error/404 feedback…
    $pod_parser->parse_file( `perldoc -l $path` );
    # [ 200, [], [ $text ] ];
    $tit->response->body([ $text ]);
};

Tit->to_app;

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
