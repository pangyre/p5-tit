#!perl
use utf8;
use strictures;
no warnings "uninitialized";
use open ":std", ":encoding(utf8)";
use Test::Fatal;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

package Apptastic {
    use utf8;
    use strictures;
    use parent "Tit";
    use Tit;

    get "/" => sub {
        [ 200, [], [ "OHAI" ] ];
    };

};

ok my $app = Apptastic->to_app, 'Apptastic->to_app';
# note $app->();

isnt exception { Tit->import },
    undef,
    "Can't use Tit twice";

isnt exception { Apptastic->import },
    undef,
    "Can't use Apptastic twice";


test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "/");
    is $res->code, 200,"200 for /";
    #is $res->content, "HERRO", "GET / returns correct content";
    #is_deeply [ $res->content_type_charset ],
    #[ "text/plain", "UTF-8" ], "text/plain and UTF-8";
};


done_testing();

__END__


{
    use Tit;
    get "/" => sub {};
    my $app = Tit->to_app;
    note $app->();
}


# ok my $app = do "t/apps/tit.psgi", "Compiled PSGI";

# Simple GET
test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "/");
    is $res->code, 200,"200 for /";
    is $res->content, "HERRO", "GET / returns correct content";
    is_deeply [ $res->content_type_charset ],
        [ "text/plain", "UTF-8" ], "text/plain and UTF-8";
};

# UTF-8 in URI.
test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "/¶");
    is $res->code, 200,"200 for /¶";
    is $res->decoded_content, "¶s are fun", "GET /¶ returns correct content";
    is_deeply [ $res->content_type_charset ],
        [ "text/plain", "UTF-8" ], "text/plain and UTF-8";
};

# Match anything URI.
test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "/any/");
    is $res->code, 404, "404 for /any/* without arg";
    for my $path ( "/any/moo", "/any/some/long/path", "/any/😜" )
    {
        my $res = $cb->(GET $path);
        my $string = [ split '/', $path, 3 ]->[-1];
        is $res->decoded_content, "ERR… $string", "GET $path returns “$string”";
        is_deeply [ $res->content_type_charset ],
            [ "text/plain", "UTF-8" ], "text/plain and UTF-8";
    }
};

# Multiple args in URI.
test_psgi $app, sub {
    my $cb  = shift;
    { # 404s…
        my @cases = qw( /five /five/ /five/a /five/a/ /five/a/b
                        /five/a/b/c /five/a/b/c/d /five/a/b/c/d/
                        /five/a/b/c/d/e/ );
        my $count;
        for my $case ( @cases )
        {
            my $res = $cb->(GET $case);
            $count++ if $res->code == 404;
        }
        ok $count == @cases, "All sub URIs of /five/*/*/*/*/* 404";
    }

    {
        my $count;
        my @cases = qw( /five/a/b/c/d/e /five/1/2/3/4/5
                        /five/α/β/γ/δ/ε
                        /five/some/longer/strings/just/because );
        for my $case ( @cases )
        {
            my $res = $cb->(GET $case);
            my @no_five = grep length, split '/', $case;
            shift @no_five;
            my $expected = join " ", @no_five;
            $count++ if $res->code == 200;
            $count++ if $res->decoded_content =~ /\Q$expected/;
        }
        ok $count == @cases * 2, "URIs of /five/*/*/*/*/* behave";
    }
};

subtest "Housekeeping" => sub {
    require_ok "Tit::Response";
    ok "Tit::Response"->is_psgi_response([ 200 ]), "[ 200 ] is_psgi_response";
    ok ! "Tit::Response"->is_psgi_response([ 600 ]), "[ 600 ] ! is_psgi_response";
    ok ! "Tit::Response"->is_psgi_response([]), "[] ! is_psgi_response";
    ok "Tit::Response"->is_psgi_response([ 200, [], [] ]), "[ 200, [], [] ] is_psgi_response";

    done_testing();
};


subtest "Router/Routes" => sub {
    plan skip_all => "Maybe in its own ::space for now…";;

    done_testing();
};

subtest "More than one app in existence at once" => sub {
    plan skip_all => "It's snipe hunt right now";
    package RouRou {
        use parent "Tit";
        use Tit;
        #use Path::Tiny;
        use strictures;

        get "/" => sub { [ 204 ] };
    };

    ok my $app = RouRou->to_app, "Made a RouRou test app";
    ok ref $app eq "CODE", "Looks legit";

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET "/");
        is $res->code, 204, "GET / OK";
            # or note explain $res;

    };

    done_testing();
};

done_testing();

__END__

