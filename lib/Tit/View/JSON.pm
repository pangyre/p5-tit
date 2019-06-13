package Tit::View::JSON {
    use Moo;
    use strictures;
    use JSON::XS;
    use Carp;

    around BUILDARGS => sub {
        my $orig = shift;
        my $class = shift;
        #my $tit = shift || confess "\$tit context object is required";
        #confess "Only allowed argument is the \$tit context object" if @_;
        $class->$orig({@_});
    };

    has json =>
        is => "ro",
        default => sub { JSON::XS->new->convert_blessed } #->utf8->pretty->allow_nonref->convert_blessed->allow_unknown },
        ;

#    $encoder->encode($data);
    sub decode {
        +shift->json->decode(+shift);
    }

    sub render {
        # use YAML; warn Dump(\@_);
        my ( $self, $tit ) = @_;
        $tit->response->header( "X-view" => __PACKAGE__ );

        my $ct = join "; ", "application/json",
            join("=", "charset", $tit->response->charset);
        $tit->response->headers([ "Content-Type" => $ct ]);
        $tit->response->body([ $self->json->encode( $tit->stash ) ]);
    }

    1;
};
