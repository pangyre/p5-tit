use inc::Module::Install;
use strict;
use warnings;

name "Tit";
all_from "lib/Tit.pm";

# cpanfile;
# auto_install;? 

requires "" => "";

WriteAll;

system "pod2markdown Tit README.md"
    if $Module::Install::AUTHOR;

exit 0;

__END__

perl_version "5.014";
requires "Router::R3" => "0.011001";
requires "Carp" => undef;
requires "Data::UUID" => undef;
requires "Encode" => undef;
requires "Exporter" => undef;
requires "HTML::Entities" => undef;
requires "HTTP::Negotiate" => undef;
requires "HTTP::Status" => undef;
requires "JSON" => undef;
requires "List::Util" => "1.50";
requires "Moo" => undef;
# requires "MooX::HandlesVia
# requires "MooX::StrictConstructor" => undef;
requires "Path::Tiny" => undef;
requires "URI::Escape" => undef;
requires "URI::QueryParam" => undef;
requires "URI" => undef;
requires "Plack" => undef;
requires "Plack::Builder" => undef;
requires "Plack::Request" => undef;
requires "Scalar::Util => "1.50";

#test_requires "Plack::App::File" => undef;
requires "Text::Xslate" => undef;
requires "Type::Tiny" => undef;
requires "Types::Standard" => undef;

requires "YAML" => undef;
requires "mro" => undef;
requires "open" => undef;

# TEST REQUIRES STUFF-
# NO? Make the tests conditional?

requires "parent "DBIx::Class::Core"" => undef;
requires "parent "DBIx::Class::ResultSet::HashRef"" => undef;
requires "parent "DBIx::Class::Schema"" => undef;
requires "parent "Plack::Request"" => undef;
requires "parent "Tit"" => undef;
requires "strictures" => undef;
requires "the app level is where we deny or allow.
requires "this software is licensed free of charge, there is no warranty
requires "utf8" => undef;
requires "with proxies that can dynamically switch to being a tunnel
