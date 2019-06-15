#!perl
use utf8;
use strictures;
no warnings "uninitialized";
use open ":std", ":encoding(utf8)";
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
# use Test::Fatal;
#use JSON;
#use URI;
use FindBin;
use lib "$FindBin::Bin/lib";
use feature "say";

# All tests should work in main:: and Package::
# Need a package collision test too, both apps…?

my $app = do "t/apps/tit.psgi";
is ref($app), "CODE", "Compiled PSGI: $app";

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
        ok $count == @cases * 2, "URIs with 5 path args to /five/*/*/*/*/* 200";
    }
};

subtest "Housekeeping" => sub {
    require_ok "Tit::Response";
    ok "Tit::Response"->is_psgi_response([ 200 ]), "[ 200 ] is_psgi_response";
    ok ! "Tit::Response"->is_psgi_response([ 600 ]), "[ 600 ] ! is_psgi_response";
    ok ! "Tit::Response"->is_psgi_response([]), "[] ! is_psgi_response";
    ok "Tit::Response"->is_psgi_response([ 200, [], [] ]), "[ 200, [], [] ] is_psgi_response";
    done_testing(5);
};


subtest "Router/Routes" => sub {
    plan skip_all => "Maybe in its own ::space for now…";
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

subtest "Built-in logging and log levels" => sub {
    # Capture warnings…
    require Tit::Log;
    use Capture::Tiny "tee"; # "capture";
    use File::Spec;

    my $log = Tit::Log->new;
    cmp_ok $log->level, "==", Tit::Log::WARN(), "Default log level is warn in numeric context";
    cmp_ok $log->level, "eq", Tit::Log::WARN(), "Default log level is warn in string context";

    subtest "WARN on default level" => sub {
        my ( $out, $err, $return ) = tee {
            $log->warn("OHAI");
        };
        like $err, qr/OHAI/, "Caught warning";
        done_testing(1);
    };

    subtest "Ignore DEBUG on default level" => sub {
        my ( $out, $err, $return ) = tee {
            $log->debug("DEBUG");
        };
        unlike $err, qr/DEBUG/, "Ignored debug";
        done_testing(1);
    };

    # This should be caught *in* the app, que no?
    subtest "FATAL on default level" => sub {
        my ( $out, $err, $return ) = tee {
            eval { $log->fatal("ODAI") };
            $@ || "[no fatal]";
        };
        like $return, qr/ODAI/, "Threw fatal"
            or note $return;
        done_testing(1);
    };

    done_testing(5);
};

done_testing(20);

__END__

MISSING TESTS… double definitions of named models, views…
