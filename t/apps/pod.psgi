#!/usr/bin/env perl
use utf8;
use strictures;
use Tit;
use Pod::Simple::Text;

#my $p = Pod::Simple::HTML->new;
#$p->output_string(\my $html);
#$p->parse_file('path/to/Module/Name.pm');
#open my $out, '>', 'out.html' or die "Cannot open 'out.html': $!\n";
#print $out $html;

get "/pod/{module:.+}" => sub {
    # $tit->response->body([ "I like… ", my $module = +shift->{module} ]);
    my $module = +shift->{module};
    my $parser = Pod::Simple::Text->new;
    $parser->output_string(\my $text);
    my $path = `perldoc -l $module` || `perldoc -l Tit`;
    $parser->parse_file( `perldoc -l $path` );
    [ 200, [], [ $text ] ];
};


$tit->to_app;

__END__


 plackup -Ilib -r t/apps/pod.psgi

=pod

=encoding utf8

=head1 Name

=head1 Synopsis

=head1 Methods

=head1 Copyright

=cut
