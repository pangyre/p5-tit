
# THIS SHOULD BE CALLED Plain

# THIS SHOULD BE A RESPONSE ROLE…??? No! Right?
package Tit::View::Text {
    use Moo;
    use strictures;
    use Carp;

    around BUILDARGS => sub {
        my $orig = shift;
        my $class = shift;
        # Carp::cluck( "HERE -> ", YAML::Dump(\@_) );
        #my $tit = shift || confess "\$tit context object is required";
        #confess "Only allowed argument is the \$tit context object" if @_;
        $class->$orig({@_});
    };

    sub render {
        # use YAML; warn Dump(\@_);
        my ( $self, $tit ) = @_;
        $tit->response->header( "X-view" => __PACKAGE__ );
        my $ct = join "; ", "text/plain", join("=", "charset", $tit->response->charset);
        $tit->response->header( "Content-Type" => $ct );
         #$tit->response->content_type("text/plain; charset=UTF8");
        #$tit->response->header( "X-view" => __PACKAGE__ );
    }

    1;
};
