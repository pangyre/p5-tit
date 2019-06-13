package Tit::Adaptor::DBIC {
    use strictures;

    sub new {
        my $adaptor_class = shift;
        my $namespace = shift;
        my $schema_class = shift;
        # Should debug the args here better; user, pass, \%attr…
        my $schema = $schema_class->connection(@_);

        my @sources = $schema->sources;
        my ( $any ) = $sources[0];
        $schema->deploy
            unless $schema->storage->dbh->tables(undef, undef, $any, "TABLE");

        my %name_resultset = ( $namespace => $schema );
        for my $source ( sort @sources )
        {
            my $name = join "::", $namespace, $source;
            $name_resultset{$name} = $schema->resultset($source);
        }
        %name_resultset;
    }

    1;
};


__END__
