# This should not be necessary?
package UncommonCourtesy {
    use strictures;
    our $AUTOLOAD;

    sub new { bless {}, __PACKAGE__ }

    sub AUTOLOAD {
        my $self = shift;
        ( my $method = $AUTOLOAD ) =~ s/\A.+:://;
        {
            no strict "refs";
            *$method = sub {
                "we don't do $method";
            }
        }
        $self->$method(@_);
    }

    sub DESTROY { 1 }

    1;
};

# Should be a view?
package MiniWiki::Marks {
    use strictures;
    use utf8;
    use Carp;
    use HTML::Entities;

    sub render {
        my $txt = shift;
        my $tit = shift || UncommonCourtesy->new;

        # confess "No, man" if @_;
        $txt =~ s/\A\s+//;
        $txt =~ s/\s+\z//;
        $txt =~ s/[^\n\S]++(?=\n)//g; # Trailing is never meaningful for display.
        $txt =~ s/\r\n/\n/g; # Just awful to have to deal with these.
        $txt = encode_entities($txt, q[><&]);

        my @titles = map $_->{title}, $tit->model("DB::Page")
            ->search({}, { order_by => 'LENGTH(title) DESC' })
            ->hashref_rs
            ->all;

        for my $title ( @titles )
        {
            $txt =~ s{\b(\Q$title\E)\b}
            { eval { sprintf '<a href="%s">%s</a>',
              $tit->uri_for_route("page/*", [$1]), $1 } || encode_entities($@) }eg;
        }
        join "\n\n", map { s/\n/<br>/g; "<p>$_</p>" } split /\n\n/, $txt;
    }

    1;
};

__DATA__

=pod

=encoding utf-8

=head1 Name

MiniWiki::Marks - …minimalist formatting…

=head1 Methods

=over 4

=item render( $text, $tit )

=back

=cut

LIST HANDLING-
    https://unix.stackexchange.com/questions/520897/convert-whitespace-to-numbered-list/520903#520903

