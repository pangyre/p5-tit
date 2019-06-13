package MiniWiki::Schema::RS {
    use strictures;
    no warnings "uninitialized";
    use parent "DBIx::Class::ResultSet::HashRef";
    use Carp "croak";

    sub rand { +shift->search(undef, { order_by => \q{ RAND() } }) }

    sub TO_JSON {
        my $self = shift;
        croak "No arguments allowed TO_JSON" if @_;
        $self->hashref_rs;
    }

    sub DBIx::Class::Row::TO_JSON { +{ +shift->get_columns } }

    1;
};

__END__


