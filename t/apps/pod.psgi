#!/usr/bin/env perl
use utf8;
use strictures;
use Tit;
use Moo;
use Pod::Simple::Text;

get "/pod/{module:.+}" => sub {
    my $module = +shift->{module};
    my $pod_parser = Pod::Simple::Text->new;
    $pod_parser->output_string(\my $text);
    my $path = `perldoc -l $module` || `perldoc -l Tit`;
    $pod_parser->parse_file( `perldoc -l $path` );
    [ 200, [], [ $text ] ];
};

$tit->to_app;

__END__

#my $p = Pod::Simple::HTML->new;
#$p->output_string(\my $html);
#$p->parse_file('path/to/Module/Name.pm');
#open my $out, '>', 'out.html' or die "Cannot open 'out.html': $!\n";
#print $out $html;

=pod

=encoding utf8

=head1 Name

pod.psgi – minimal POD viewer.

=head1 Synopsis

 plackup -Ilib -r t/apps/pod.psgi

=cut
