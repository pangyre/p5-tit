# Write? -> Text::Xslate::Bridge::Tit

package Tit::View::Xslate {
    use Moo;
    use strictures;
    use Text::Xslate;
    use Path::Tiny;
    use Carp;

#    around BUILDARGS => sub {
#        my $orig = shift;
#        my $class = shift;
#        # my $tit = shift || confess "\$tit context object is required";
#        # confess "Only allowed argument is the \$tit context object" if @_;
#        $class->$orig({ root => path( $tit->home, "root" ),
#                        # tit => $tit,
#                      }); # … :|
#    };

    around BUILDARGS => sub {
        my $orig = shift;
        my $class = shift;
        my $xslate = Text::Xslate->new(@_);
        $class->$orig({ xslate => $xslate });
    };

    has xslate =>
        is => "ro",
        required => 1,
        ;

    sub _build_xslate {
        my $self = shift;
        # https://metacpan.org/source/SKAJI/Text-Xslate-v3.5.6/example/bridge.pl
        Text::Xslate->new( path => $self->root,
                           module => ['Text::Xslate::Bridge::Star'] );
    }

    sub render {
        # use YAML; warn Dump(\@_);
        my ( $self, $tit ) = @_;
        my $template = $tit->stash->{template};
        unless ( $template )
        {
            ( my $tmp = $tit->route->definition ) =~ s,/{[^}]+}/,/,g;
            $tmp =~ s, (?<=/) { ( [^:}]+ ) (?: :[^}]+ )? } ,$1,gx;
            # ( my $tmp = $tit->route->action_path ) =~ s{/\*}{}g;
            $tmp = "/index" if $tmp eq "/";
            $template = ( $tmp || "index" ) . ".tx"; # DEFINE suffix in config?
        }
        $tit->response->header( "X-view" => __PACKAGE__ );
        my $ct = join "; ", $tit->response->content_type || "text/html",
            join("=", "charset", $tit->response->charset);
        $tit->response->headers([ "Content-Type" => $ct ]);
        my %vars = ( %{ $tit->request->captures },
                     %{ $tit->stash } );
        # warn "TEMPATE -> $template";
        [ $self->xslate->render( $template, { %vars, tit => $tit }) ];
    }

    1;
};

__END__

