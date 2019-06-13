#!perl
use 5.18.2;
use strictures;
use open ":std", ":encoding(utf8)";
use Test::More;
use Plack::Test;
use HTTP::Request::Common qw/ GET HEAD PUT POST DELETE /;
use Encode;
#use WWW::Mechanize;
# use Test::Fatal;
use JSON::XS;
#use URI;
use FindBin;
use lib "$FindBin::Bin/lib";

require_ok "MiniWiki";

ok "ok" eq eval 'use MiniWiki; "ok"', "use MiniWiki"
    or note $@ || "Unknown load error…";

ok my $mw = MiniWiki->build, "MiniWiki->build";
ok my $app = MiniWiki->to_app, "MiniWiki->to_app";
ok my $app2 = $mw->to_app, "\$miniwiki->to_app";
is_deeply $app, $app2, "Both invocants of app return same app";

note explain $app;

#subtest "All good tests go to heaven" => sub {
#    plan skip_all => $mw->home . "…";
#    # t/fixture/wiki-pages.json
#    done_testing();
#};

test_psgi $app, sub {
    my $cb  = shift;
    my $path = "some/ridiculous/thing"; # Check the 404 too.
    my $res = $cb->(GET "/uri/$path");
    like $res->content, qr/\Q$path/, $res->request->uri->path . " contains $path";
};

# Router related pseudoheisenbug.
test_psgi $app, sub {
    my $cb  = shift;
    my $ok = 0; my $tries = 500;
    for ( 1 .. $tries )
    {
        my $res = $cb->(GET "/routes");
        $ok += $res->code == 200;
    }
    ok $tries == $ok, "GET /routes $tries times 100% success"
        or note sprintf "Only %.1f%% OK!", 100 * ( $ok / $tries );
};

# PUT JSON, full boat.
test_psgi $app, sub {
    use JSON::XS;
    use Path::Tiny;
    my $cb = shift;
    my $fixture = decode_json( path("$FindBin::Bin/fixture/wiki-pages.json")->slurp_raw );

    for my $page ( @{$fixture} )
    {
        my $res = $cb->( PUT "/page/$page->{title}",
                         "Content-Type" => "application/json; charset=utf-8",
                         Content => encode_json({ content => $page->{content} }) );
        ok $res->is_redirect || $res->is_success, "Start in known state: PUT /page/$page->{title}"
            or note $res->content;
    }

    for my $page ( @{$fixture} )
    {
        my $res = $cb->( DELETE "/page/$page->{title}", "Accept" => "application/json; charset=utf-8" );
        ok 200 == $res->code, "DELETE /page/$page->{title} " . $res->code
            or note "Got -> " . $res->code;
        my $res_page = eval { decode_json $res->content };
        # note $res->content . " " . $@ if $@;
        # $_ = decode("UTF-8", $_) for values %$res_page;
        # note explain $page;
        # note $res_page->{content};
        is_deeply $res_page, $page, "Fixture page == DELETE entity";
    }

    for my $page ( @{$fixture} )
    {
        my $res = $cb->( PUT "/page/$page->{title}",
                         "Content-Type" => "application/json; charset=utf-8",
                         Content => encode_json({ content => $page->{content} }) );
        ok 201 == $res->code, "PUT /page/$page->{title} " . $res->code
            or note "Got -> " . $res->code;
    }

    # DELETE FIRST
    # THEN CREATE -> 201
    # edit -> 303
    # Same edit -> 304
    # is $res->code, 303;
    # note "RESPONSE -> " . $res->content;
};

done_testing();

exit 0;

test_psgi $app, sub {
    use JSON::XS;
    use Path::Tiny;
    my $cb = shift;
    my $fixture = decode_json( path("$FindBin::Bin/fixture/wiki-pages.json")->slurp_raw );
    ok my $page = shift @{$fixture};
    # note explain $page;
    my $res = $cb->( PUT "/page/$page->{title}",
                     "Content-Type" => "text/plain; charset=utf-8",
                     Content => encode("UTF-8", $page->{content}) );
    note $res->content;
};

done_testing();
exit;

# Single and mass populate–
test_psgi $app, sub {
    use JSON::XS;
    use Path::Tiny;
    my $cb  = shift;
    my $fixture = decode_json( path("$FindBin::Bin/fixture/wiki-pages.json")->slurp_raw );
    for my $page ( @{$fixture} )
    {
        #my $uri = "/page/$page->{title}";
        #my $req = PUT $uri;
        #$req->header( "Content-Type" => "application/json" );
        my $uri = "/page";
        my $req = POST $uri, [ title => $page->{title}, content => $page->{content} ];
        #$req->header( "Content-Type" => "application/x-www-form-urlencoded" );
        #$req->content( encode_json([$page->{content}]) );
        # note $req->as_string;
        my $res = $cb->($req);
        # is $res->code, 301, "PUT $uri is_success"
        is $res->code, 301, "POST $uri is_success"
            or note $res->decoded_content;
        # note explain $res;
    }
    
};



# JSON part of testing…
#my $ua = LWP::UserAgent->new();
#$ua->default_header( Accept => "application/json" );
#$ua->default_header( Accept_Language => "en_US" );
# GET "/", [ Accept => "application/json" ]

done_testing();

say "# KTHANX BAI";

__END__
