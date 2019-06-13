use utf8;
use 5.18.2;

package Tit::REST {
    use strictures;
    require Tit;
    # use Carp;

    package Tit::Request {
        use strictures;
        use Encode;
        use JSON::XS;
        use Carp;

        # Should cache…
        sub data {
            my $self = shift;
            # return $self->data if $self->data;
            # THIS STUFF can go into the REST package??? No, REST should be built-in.
            my ( $ct, $encoding ) = split /;\s*charset=/i, $self->header("content_type");
            my $data;
            if ( $ct eq "application/json" )
            {
                return decode_json($self->content); # Knows how to do charset (UTF-8 at mininum).
            }
            elsif ( $ct eq "application/x-www-form-urlencoded" )
            {
                return $self->body_parameters;
            }
            else
            {
                croak "No data parsing for $ct";
            }
            #elsif ( $ct =~ /\A(?:x?html)\b/ )
            #{
            #    # Nothing? Convert to HTML5 and sanitize?
            #}
            #elsif ( $ct =~ /\Axml\b/ )
            #{
            #    croak "Stop trying to make XML happen. It's not going to happen.\n";
            #}
            #elsif ( $ct eq "text/plain" )
            #{
            #    # NO, right? It's already the content… $self->_data($);k
            #    # NO, right? It's already the content… $self->_data($);
            #}
        }

        1;
    };

    package Tit::Response {
        use strictures;
        # All the codes with what they are allowed to return.

    };

    package Tit::View::REST {
        use strictures;

    };

    1;

};
__END__
