package MiniWiki::Schema {
    use strictures;
    use parent "DBIx::Class::Schema";

    __PACKAGE__->load_namespaces( default_resultset_class => "+MiniWiki::Schema::RS" );
    # My::Schema::Results_C::Foo takes precedence over My::Schema::Results_B::Foo :
    # result_namespace => [ 'Results_A', 'Results_B', 'Results_C' ],
    # ^^^ Smarter than what you did.

    1;
};




__END__
