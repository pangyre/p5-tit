use utf8;

# From Log::Log4perl::Level -> $OFF $FATAL $ERROR $WARN $INFO $DEBUG $TRACE $ALL

package Tit::Log {
    use strictures;
    use feature "state";
    use Moo;
    use open ":std", ":encoding(utf8)";
    use Carp "croak";
    use Scalar::Util "dualvar";

    use constant ALL   => dualvar 0b111, "ALL";
    use constant FATAL => dualvar 0b110, "FATAL";
    use constant ERROR => dualvar 0b101, "ERROR";
    use constant WARN  => dualvar  0b11, "WARN";
    use constant DEBUG => dualvar  0b10, "DEBUG";
    use constant INFO  => dualvar   0b1, "INFO";
    use constant TRACE => dualvar   0b0, "TRACE";

    # use Carp;
    # use Sub::Quote; to optimize away the subs? Can you even?

    # Resetting should be allowed with warnings.
    has level =>
        is => "lazy",
        isa => sub { $_[0] >= TRACE && $_[0] <= ALL
                         or croak "$_[0] must be one of Tit::Log -> TRACE…FATAL" };
    sub _build_level { WARN }

    #has output => default to STDERR but allow fh/logfile?
    #    is => "lazy",
    #    default => sub { 

    sub fatal :method {
        my $self = shift;
        return 1 if $self->level > FATAL;
        die @_, $/;
    }

    sub error :method {
        my $self = shift;
        return 1 if $self->level >  ERROR;
        print STDERR @_, $/;
    }

    sub warn :method { # Is that enough for the compiler?
        my $self = shift;
        return 1 if $self->level > WARN;
        print STDERR @_, $/;
    }

    sub info :method {
        my $self = shift;
        return 1 if $self->level > INFO;
        print STDERR @_, $/;
    }

    sub debug :method {
        my $self = shift;
        return 1 if $self->level > DEBUG;
        print STDERR @_, $/;
    }

    sub trace :method {
        my $self = shift;
        return 1 if $self->level > TRACE;
        print STDERR @_, $/;
    }

    1;

    # CHANGE the warn to a formatted thing with a caller mini-stack of some variety…
};

__END__

=pod

=encoding utf8

=head1 Name

Tit::Log – a simplistic logger or placeholder for a real one.

=head1 Synopsis

=head1 Methods

=over 4

=item …

=back

=head1 See Also

L<Tit::Manual>, L<Tit>.

=cut
