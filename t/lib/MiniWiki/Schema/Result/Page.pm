package MiniWiki::Schema::Result::Page {
    use strictures;
    use parent "DBIx::Class::Core";

    __PACKAGE__->table( __PACKAGE__ =~ /(\w+)\z/ );

    __PACKAGE__->add_columns(
        title => { data_type => "VARCHAR",
                   default_value => undef,
                   is_nullable => 0,
                   size => 64 },
        content => { data_type => "TEXT",
                     default_value => undef,
                     is_nullable => 0,
                     size => 64 });

    __PACKAGE__->set_primary_key("title");

    1;
};

__END__
