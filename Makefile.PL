use inc::Module::Install;
use strict;
use warnings;

perl_version "5.014";
name "Tit";
all_from "lib/Tit.pm";

# cpanfile;
# auto_install;? 
requires "Router::R3" => "0.011001";
requires "strictures" => "1";
requires "Carp" => undef;
requires "Encode" => undef;
requires "Exporter" => undef;
requires "HTML::Entities" => undef;
requires "HTTP::Negotiate" => undef;
requires "HTTP::Status" => undef;
requires "JSON" => undef;
requires "List::Util" => "1.50";
requires "Moo" => undef;
requires "MooX::HandlesVia" => undef;
requires "Data::UUID" => undef;
requires "Path::Tiny" => undef;

requires "URI" => undef;
requires "URI::QueryParam" => undef;
requires "URI::Escape" => undef;

requires "Plack" => undef;
requires "Plack::Builder" => undef;
requires "Plack::Request" => undef;
requires "Plack::Session" => undef;
requires "Scalar::Util" => "1.50";

WriteAll;

system "pod2markdown lib/Tit.pm README.md"
    if $Module::Install::AUTHOR;

exit 0;

__END__

#test_requires "Plack::App::File" => undef;
requires "Text::Xslate" => undef;
requires "Type::Tiny" => undef;
requires "Types::Standard" => undef;

requires "YAML" => undef;
requires "mro" => undef;
requires "open" => undef;

# TEST REQUIRES STUFF-
# NO? Make the tests conditional?
