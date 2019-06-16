use 5.14.0;
use utf8;
use strictures;
use open ":std", ":encoding(utf8)";
use URI::QueryParam;
$URI::DEFAULT_QUERY_FORM_DELIMITER = ";"; # YOU"RE NOT MY PROGRAMMING SUPERVISOR!

package Tit::Request {
    use parent "Plack::Request";
    use Plack::Util::Accessor qw( captures accept );
    1;
}

package Tit::Response {
    use Moo;
    extends "Plack::Response";
    use Carp "croak";
    use Scalar::Util "blessed";
    use HTTP::Status "status_message";
    use Encode;

    sub decoded_content {
        my $self = shift;
        my $charset = [ $self->content_type_charset ]->[1];
        decode( $charset, $self->content, Encode::FB_CROAK );
    }

    sub is_psgi_response {
        my $class = shift;
        no warnings "uninitialized";
        croak "Only accepts one argument" if @_ > 1;
        return 1 if blessed $_[0] eq __PACKAGE__;
        return unless "ARRAY" eq ref $_[0];
        if ( $_[0][0] and status_message( $_[0][0] ) )
        {
            return 1 if @{$_[0]} == 1;
            return 1 if 2 == grep { "ARRAY" eq ref } $_[0][1], $_[0][2];
        }
        undef;
    }

    # CHANGE TO content_type_charset
    has charset =>
        is => "ro",
        default => sub { "utf-8" },
        ;

    has request =>
        is => "ro",
        writer => "_set_request",
        isa => sub { blessed $_[0] eq "Tit::Request" or croak "Must be a Tit::Request" },
        ;

    sub FOREIGNBUILDARGS {
        my ( $class, $args ) = @_;
        return 200 unless $args;
        $args = $args->{args}; # STUPID… WHY NO BUILDARGS?!?!?!?
        $args->[0] ||= 200;
        $args->[1] ||= [];
        $args->[2] ||= [];
        $args->[0], $args->[1], $args->[2];
    }

    my $done;
    sub done {
        my $self = shift;
        $done ||= shift if @_;
        $done || $self->body;
    }

    1;
}

package Tit::Route {
    use Moo;
    use MooX::StrictConstructor;
    use Carp;
    use Types::Standard "Enum";
    use Encode;

    has method =>
        is => "ro",
        required => 1,
        isa => Enum[qw/ OPTIONS GET HEAD POST PUT DELETE TRACE CONNECT /],
        # ^^^ Right? Because the app level is where we deny or allow.
        ;

    has path =>
        doc => "The path *without* arguments",
        is => "ro",
        required => 1,
        ;

    has definition =>
        doc => "The actual route for R3 to consume, *with* arguments",
        is => "ro",
        required => 1,
        ;

    has action_path =>
        is => "ro",
        required => 1,
        ;

    has args =>
        is => "ro",
        isa => sub { ref $_[0] eq "ARRAY" or croak "args must be an array reference" },
        ;

    has argspec =>
        is => "ro",
        isa => sub { ref $_[0] eq "ARRAY" or croak "args must be an array reference" },
        ;

    has code =>
        is => "ro",
        required => 1,
        isa => sub { ref $_[0] eq "CODE"
                         or croak "code must be a code reference" },
        ;

    sub dump_code {
        "sub { DUMMY }";
        #require B::Deparse;
        #my $code = B::Deparse->new->coderef2text(+shift->code);
        #$code =~ s/(?<=\n)    //g;
        #$code =~ s/\A\{\n|\n\}\z//g;
        #$code;
    }

    has view =>
        is => "ro", # Yeah?
        ;

    has _method_path =>
        is => "lazy",
        init => undef,
        ;

    sub _build__method_path {
        my $self = shift;
        encode("UTF-8", join("", "/", $self->method, $self->definition), Encode::FB_CROAK );
    }

    1;
};

package Tit::Router {
    use Moo;
    # use MooX::HandlesVia;
    use Router::R3;
    use Carp;
    use Scalar::Util "blessed";
    use Encode;
    use List::Util "pairs", "max";
    use JSON::XS;

    # Should be a finalized/locked??? Maybe should be class data???
    has routes =>
        is => "ro",
        default => sub { [] },
        # isa => Map[ Str, Tit::Route ], # The Str should be defined by R3's reqs.???
        isa => sub { ref $_[0] eq "ARRAY"
                         or croak "routes must be an array reference" },
        ;

    my %map;
    sub route {
        my $self = shift;
        my $route_name = shift || croak "Route action_path is required";
        $route_name =~ s{\A(?!/)}{/};
        $map{$route_name} || croak "No such route: $route_name";
    }

    sub add_route {
        my $self = shift;
        my $route = shift;
        croak "Too many arguments to add_route" if @_;
        $route->isa("Tit::Route") or croak "$route is not a Tit::Route";
        # $map{$route->_method_path} = $route;
        $map{$route->action_path} = $route;
        push @{$self->routes}, $route;
    }

    sub match {
        +shift->_router->match(+shift);
    }

    has _router =>
        is => "lazy",
        isa => sub { blessed $_[0] eq "Router::R3"
                         or croak "Only router allowed is Router::R3" },
        ;

    sub _build__router {
        my $self = shift;
        my %dup;
        $dup{$_->_method_path}++ && croak "Duplicate route ", $_->_method_path
            for @{ $self->routes };
        # ^^^ SHOULD BE IN add_route?

        # Nicer introspection ordering…
        @{ $self->routes } = sort { $a->definition cmp $b->definition
                                        || $a->method cmp $b->method }
                             @{ $self->routes };

        my $max = max map length $_->action_path, @{ $self->routes };
        for ( @{ $self->routes } )
        {
            if ( my $args = $_->args )
            {
                my $pad = $max - length $_->action_path;
                warn sprintf("%10s %s %s %s\n",
                             $_->method,
                             $_->action_path,
                             " " x $pad,
                             encode_json($args));
            }
            else
            {
                warn sprintf("%10s %s\n",
                             $_->method,
                             $_->action_path);
            }
        }

        my @map = map { $_->_method_path, $_ } @{ $self->routes };
        Router::R3->new([ @map ]);
    }

    sub DEMOLISH { # This is all it took to fix the R3 free unreferenced SV / exit 11 stuff.
        # my ( $self, $in_global_destruction ) = @_;
        1;
    }

    1;
}

package Tit v0.0.1 {
    use utf8;
    # use MooX::StrictConstructor;
    # ^^^ Breaks with Via below … 
    use Moo;

    use Path::Tiny;
    use URI;
    use Carp;
    use Encode;
    use MooX::HandlesVia;
    use Scalar::Util "blessed";
    use HTTP::Negotiate ();
    use Data::UUID;
    use Plack::Builder;
    # use Exporter "import";
    # use Tit::REST;

    our $AUTHORITY  = "cpan:ASHLEY";
    our $REPOSITORY = "https://github.com/pangyre/p5-tit"; # Private -> "https://bitbucket.org/pangyre/wren/";
    our @ISA;
    push @ISA, "Exporter";
    
    our ( $tit, $res, $req );
    our @EXPORT = qw( $tit get put post del add_view add_model );

    my $CALLER;
    sub import {
        $CALLER = ( caller(0) )[0];
        __PACKAGE__->export_to_level(1, @_);
    }
 
    sub BUILD {
        confess "Only one instance of Tit allowed" if $tit;

        my $self = shift;
        unless ( $self->{home} )
        {
            for ( 0 .. 12 ) # Padding in case.
            {
                # warn "Caller 0 -> ", ( caller($_) )[0];
                if ( ( caller( $_ + 1 ) )[0] eq "main" ) # Not sure this is good/right heuristic.
                {
                    # HHHHHHHHHHHMMMMMMMMMMMMMMMM…
                    my ( $package, $home )  = ( caller($_) )[0,1];
                    use Path::Tiny;
                    $self->{package} = $package;
                    $self->{home} = path($home)->parent->parent->absolute;
                    last;
                }
            }
        }
    }

    $tit = Tit->new;
    sub build {
        $tit->to_app;
        $tit;
    }
    # Not anymore: Placeholder for compilation.
    # This could be a CTX style replaced by a C style…?
    # It could be caller specific so to have any that share space, you
    # just call them from a new namespace.

    use Router::R3;
    my $ROUTER;
    my @RAW_ROUTES;

    my %config = ( REPOSITORY => $REPOSITORY );
    sub config {
        my $ctx = shift;
        return $config{+shift} if ( @_ == 1 );
        %config = ( %config, @_ ) unless @_ % 2;
        \%config;
    }

    # has debug =>
    # Set debug level?
    # Same as or different from log level?
    has log =>
        is => "lazy",
        default => sub { require Tit::Log; Tit::Log->new };

    has stash =>
        is => "lazy",
        clearer => 1,
        default => sub { +{} },
        ;

    has _models =>
        is => "lazy",
        handles_via => "Hash",
        default => sub {; {} },
        handles => {
            model => "get",
            _add_model => "set",
            models => "keys",
        },
        ;

    sub add_model {
        my $caller;
        $caller = shift
            if $_[0] eq $CALLER || blessed $_[0];

        my $name = shift;
        my $model = shift;

        if ( blessed $model )
        {
            $tit->_add_model( $name => $model );
        }
        else
        {
            eval "use $model;";
            die $@ if $@;

            if ( $_[0] eq "-adaptor" )
            {
                my ( $flag, $adaptor ) = splice @_, 0, 2;
                $adaptor =~ s{\A(?<!Tit::Adaptor::)}{Tit::Adaptor::};
                eval "use $adaptor;";
                die $@ if $@;
                my %name_model = $adaptor->new( $name => $model, @_ );
                for my $name ( keys %name_model )
                {
                    $tit->_add_model( $name => $name_model{$name} );
                }
            }
            else
            {
                $model = $model->new(@_);
                $tit->_add_model( $name => $model );
            }
        }
    }

    has _views =>
        is => "lazy",
        handles_via => "Hash",
        default => sub { +{} },
        handles => {
            view => "get",
            _add_view => "set",
            views => "keys",
        },
        ;

    my %_views;
    sub add_view {
        my $caller;
        $caller = shift
            if $_[0] eq $CALLER || blessed $_[0];

        # my $class = shift; #  if $_[0] eq __PACKAGE__ || blessed($_[0]); # Too much
        my $name = shift;
        my $view = @_ ? +shift : $name;
        my @arg = @_; # Echo whatever the package wants…

        croak "Already defined $name view" if $_views{$name}++;

        unless ( blessed $view )
        {
            $view =~ s/\A(?!Tit::View::)/Tit::View::/ unless $view =~ s/\A\+//;
            eval "use $view";
            confess $@ if $@;
            # $view = $view->new($tit, @arg);
            $view = $view->new(@arg);
        }
        warn "Adding view $name => $view\n";
        $tit->_add_view( $name => $view );
    }

    has default_view =>
        is => "lazy",
        writer => "set_default_view",
        ;

    sub _build_default_view {
        my $self = shift;
        if ( my @views = $self->views )
        {
            $self->view("Plain") || $self->view($views[0]);
        }
        else
        {
            require Tit::View::Plain;
            Tit::View::Plain->new;
        }
    }

    has session => 
        is => "ro",
        clearer => 1,
        writer => "_set_session",
        # isa => sub { blessed $_[0] eq 
        ;

    # Too smart by half?
    has "package" =>
        is => "ro",
        required => 1,
        init_arg => undef,
        default => sub { $CALLER }, # MAYBE only do it if it's NOT main??? Rebless?
        ;

    has home =>
        is => "ro",
        required => 1,
        #init_arg => undef,
        #default => sub { ... },
        ;

    # Y THO?
    sub static_uri { # Caller?
        my ( $self, @path ) = @_;
        URI->new_abs( path( @path ), $req->uri );
        # URI->new_abs( path( $self->static_root, @path ), $req->uri );
    }

    sub uri_for { # Caller?
        my ( $self, @path ) = @_;
        URI->new_abs( path(@path), $req->uri );
    }

    use URI::Escape;
    sub uri_for_route { # Route method? It could do relative URIs…?
        my $self = shift;
        # use YAML; warn YAML::Dump(@_);
        my $rthing = shift || croak "Route is required";
        my $route = blessed $rthing ? $rthing : $self->router->route($rthing);
        my $action_path = encode("UTF-8", $route->action_path); # Y THO?
        # my $action_path = $route->action_path;

        my $query = pop if "HASH" eq ref $_[-1];
        my $args = pop if "ARRAY" eq ref $_[-1]; # SHOULD this have been decode'd?
        #no warnings "uninitialized";
        # warn "ARGS: ", $route->definition, " $args";
        # my $uri = URI->new_abs("", $req->uri);
        croak $action_path, " does not take arguments" if $args and not $route->args;

        if ( my $required = $route->args )
        {
            croak "uri_for_route: ", $route->definition, " requires arguments: …"
                unless $args;

            # warn "required args -> ", join " ", map { $_ // "{NO ARG}" } @$required;
            croak sprintf("[ %s ] does not match requirement -> %s", join(", ", @$args), $action_path )
                unless @$args == @$required;

            for ( my $i = 0; $i < @{$required}; $i++ )
            {
                my $swap = uri_escape(shift @$args, '^A-Za-z0-9\\-\\._~\\x{80}-\\x{10FFFF}');
                length $swap || croak "Missing argument to ", $route->action_path, " in position $i";
                $action_path =~ s{(?<=/)\*}{$swap};
            }
        }

        # my $uri = URI->new_abs($flat, $req->uri);
        my $uri = URI->new_abs($action_path, $req->uri);
        $uri->query_form_hash($query) if $query;
        # print STDERR "Returned route -> ", $uri, $/;
        $uri;
    }

    has request =>
        is => "rwp";

    has response =>
        is => "rwp";

    has route =>
        is => "rwp",
        clearer => 1,
        ;

    has router =>
        is => "lazy",
        # weak_ref => 1,
        isa => sub { $_[0]->isa("Tit::Router")
                         or confess "Not a Tit::Router" },
        default => sub { Tit::Router->new }
        ;

    sub flash {
        my $self = shift;
        croak "Some argument is required: name or key => value" unless @_;
        return $self->session->remove(+shift)
            if @_ == 1;
        my %arg = @_; # To blow up on uneven.
        $self->session->set( $_ => $arg{$_} ) for keys %arg;
    }

    # We could have a chain or follow method…?

    sub get ($&;$) {
        # duplicates…
        # push @RAW_ROUTE, @_[0,1], [caller];
        my $uri = URI->new_abs(+shift, "/");
        my $code = shift; # SHOULD BE ABLE TO OMIT!
        my $view = shift || $tit->default_view; # This is also in the dipatch and it only should be I think.
        # Check that the view has been added???

        my $path = decode("UTF-8", join("/", map { s/\{[^}]+\}/*/; $_ } $uri->path_segments), Encode::FB_CROAK);
        my $definition = decode("UTF-8", join("/", $uri->path_segments), Encode::FB_CROAK);
        my @args = $definition =~ /{([^:}]+)((?::[^}]+)?)}/g;
        ( my $action_path = $definition ) =~ s/{([^:}]+)(?::[^}]+)?}/*/g;

        use List::Util "pairs";
        my $route = Tit::Route->new({ method => "GET",
                                      definition => $definition,
                                      action_path => $action_path,
                                      ( argspec => \@args ) x !! @args,
                                      ( args => [ map $_->[0], pairs @args ] ) x !! @args,
                                      view => $view,
                                      path => $path,
                                      code => $code });

        $tit->router->add_route( $route );
        #warn $route->definition;
        #push @RAW_ROUTES, join( " ", "GET" => encode("UTF-8", $route->definition, Encode::FB_CROAK) ), $code;
        push @RAW_ROUTES, join(" ", "GET" => $route->definition), $code;
    }

    sub post ($&) {
        my $uri = URI->new_abs(+shift, "/");
        my $code = shift; # SHOULD BE ABLE TO OMIT!
        my $view = shift || $tit->default_view; # This is also in the dipatch and it only should be I think.
        # Check that the view has been added???

        my $path = decode("UTF-8", join("/", map { s/\{[^}]+\}/*/; $_ } $uri->path_segments), Encode::FB_CROAK);
        my $definition = decode("UTF-8", join("/", $uri->path_segments), Encode::FB_CROAK);
        my @args = $definition =~ /{([^:]+)((?::[^}]+)?)}/g;
        ( my $action_path = $definition ) =~ s/{([^:]+)(?::[^}]+)?}/*/g;

        use List::Util "pairs";
        my $route = Tit::Route->new({ method => "POST",
                                      definition => $definition,
                                      action_path => $action_path,
                                      ( argspec => \@args ) x !! @args,
                                      ( args => [ map $_->[0], pairs @args ] ) x !! @args,
                                      view => $view,
                                      path => $path,
                                      code => $code });

        $tit->router->add_route( $route );

        push @RAW_ROUTES, join( " ", "POST" => $route->definition ), $code;
    }

    sub put ($&) {
        my $uri = URI->new_abs(+shift, "/");
        my $code = shift; # SHOULD BE ABLE TO OMIT!
        my $path = decode("UTF-8", join("/", map { s/\{[^}]+\}/*/; $_ } $uri->path_segments), Encode::FB_CROAK);
        my $definition = decode("UTF-8", join("/", $uri->path_segments), Encode::FB_CROAK);
        my @args = $definition =~ /{([^:]+)((?::[^}]+)?)}/g;
        ( my $action_path = $definition ) =~ s/{([^:]+)(?::[^}]+)?}/*/g;

        use List::Util "pairs";
        my $route = Tit::Route->new({ method => "PUT",
                                      definition => $definition,
                                      action_path => $action_path,
                                      ( argspec => \@args ) x !! @args,
                                      ( args => [ map $_->[0], pairs @args ] ) x !! @args,
                                      view => undef,
                                      path => $path,
                                      code => $code });

        $tit->router->add_route( $route );

        push @RAW_ROUTES, join( " ", "PUT" => $route->definition ), $code;
    }

    sub del ($&) {
        my $uri = URI->new_abs(+shift, "/");
        my $code = shift;
        my $path = decode("UTF-8", join("/", map { s/\{[^}]+\}/*/; $_ } $uri->path_segments), Encode::FB_CROAK);
        my $definition = decode("UTF-8", join("/", $uri->path_segments), Encode::FB_CROAK);
        my @args = $definition =~ /{([^:]+)((?::[^}]+)?)}/g;
        ( my $action_path = $definition ) =~ s/{([^:]+)(?::[^}]+)?}/*/g;

        use List::Util "pairs";
        my $route = Tit::Route->new({ method => "DELETE",
                                      definition => $definition,
                                      action_path => $action_path,
                                      ( argspec => \@args ) x !! @args,
                                      ( args => [ map $_->[0], pairs @args ] ) x !! @args,
                                      view => undef,
                                      path => $path,
                                      code => $code });

        $tit->router->add_route( $route );

        push @RAW_ROUTES, join( " ", "PUT" => $route->definition ), $code;
    }

    sub visit {
        #my $self = shift;
        #my $route = shift;
        #join " + ", $self, $route, $self->router->route($route);
        # my $route = +shift->router->route(+shift);
        +shift->router->route(+shift)->code->(@_);
    };

    my %apps;
    sub to_app {
        if ( $apps{$tit->package} )
        {
            carp "You can only build the app once";
            return $apps{$tit->package};
        }
        use YAML ();
        #require Plack::Request;
        #require Plack::Response;
        require Plack::Session;
        use URI::Escape;
        # $tit = Tit->new;

        # THIS MUST BE CONFIGURABLE and build now… after all the views
        # have been added and such.
        my @allowed = ( [ "Xslate", 1.0, "text/html" ],
                        [ "JSON", 1.0, "application/json" ],
                        [ "Plain", 0.5, "text/plain" ] );

        $tit->router->_router; # Time to build it.

        # 321
        add_view "Plain"
            unless $tit->views;

        my $APP = sub {
            my $env = shift;
            $tit->clear_route;
            $tit->clear_stash;
            $tit->_set_session( Plack::Session->new($env) ); # ->{'psgix.session'} );
            $tit->_set_request( $req = Tit::Request->new($env) );
            $tit->_set_response( $res = Tit::Response->new );
            $req->accept( my $prefer = HTTP::Negotiate::choose( \@allowed, $req->headers ) );

            eval {
                # warn "HEADERS -> ", $req->headers->{"content-type"};
                # warn "HEADERS -> ", $req->headers->{"x-http-method-override"};
                my $method = $req->headers->{"x-http-method-override"}
                    || $req->body_parameters->get("X-HTTP-Method-Override")
                        || $req->method;

                # warn "DISPATCH -> ", join " ", $method, decode("UTF-8",$req->path_info), sprintf("(%s)", $req->accept), $/;

                my ( $route, $tmp ) = $tit->router->match( join "", "/", $method, $req->path_info );
                my $captures;
                for my $k ( keys %{$tmp} )
                {
                    my $v = decode("UTF-8", delete $tmp->{$k}, Encode::FB_CROAK);
                    $k = encode("UTF-8", $k, Encode::FB_CROAK);
                    $captures->{$k} = $v;
                }
                # warn "ROUTE -> ", $route || "[no match]";
                $tit->_set_route( $route );
                $req->captures( $captures || {} ); # Not Moo… yet?
                $res->_set_request($req);
                if ( $route )
                {
                    #warn " Matched -> ", $method, " ", $route->action_path, $/;
                    #warn "    View -> ", $route->view || $tit->default_view, $/;

                    # warn "Matched route-\n", YAML::Dump($route);
                    my $response = eval { $route->code->( $captures ) };

                    warn "<<$@>>",
                        join " ", $method, decode("UTF-8",$req->path_info), sprintf("(%s)", $req->accept), $/
                            if $@;

                    # warn "RESPONSE-> search/{q} | ", $response || "NONE YET";
                    #warn "RES->BODY-> search/{q} | ", $tit->response->body || "NONE YET";
                    # confess decode("UTF-8", $req->method . " " . $req->path_info), " -> ", $@ if $@;
                    # confess decode("UTF-8", $req->method . " " . $req->path_info), " -> ", ( $@ || "Unknown error" )  if $@;
                    no warnings "uninitialized";
                    if ( $response && Tit::Response->is_psgi_response( $response ) )
                    {
                        # warn "HERE => ", YAML::Dump($response);
                        $tit->_set_response( $res = "Tit::Response"->new({ args => $response }) );
                    }
                    elsif ( $response && "Tit::Response" eq blessed $response )
                    {
                        $tit->_set_response( $res = $response );
                    }
                    elsif ( ! @{ $res->body || [] } )
                    {
                        # $res->body( ["No proper pre-render pass"] );
                        # ^^^ Fixes bug in Text but causes bug in Xslate,
                    }
                    else # There is a body already, right? Don't render.
                    {
                        # croak "WAT?";
                        # $res->body( $view->render($tit) ) unless $tit->response->done;
                        # $_ = decode( $res->charset, $_, Encode::FB_CROAK ) for @{ $res->body };
                    }
                    $res->_set_request($req); # More like LWP. Why is this down here?
                }
                else
                {
                    # Errors should respect views.
                    $res->status(404);
                    $res->headers([ "Content-Type" => "text/plain; charset=utf-8" ]);
                    $res->body([ "Not found ", decode("UTF-8", uri_unescape($req->uri->path), Encode::FB_CROAK),
                                 " -> ", uri_unescape($req->uri->path),
                                 $/,
                                 " -> ", $req->uri->path,
                                 $/, $/,
                                 $tit->package,
                                 # $/, $/,
                                 # YAML::Dump($tit), # R3 crashes server.
                               ]);
                    return $res->finalize;
                }

                # warn "RES->BODY-> search/{q} | ", $tit->response->body || "NONE YET";;
                {
                    no warnings "uninitialized";
                    # warn "BODY -> ", YAML::Dump($res->body);
                    return if @{ $tit->response->body || [] } || $res->status =~ /\A3\d\d/;
                }

                # Opinion, user choice is more important.
                # warn "PREVIEW -> ",  $prefer || $route->view || $tit->default_view;
                # Iterate through prefered? Then fall to default. Right?

                my $view_name = $prefer || $route->view || $tit->default_view;
                # NOT YET and probably not here -> $view_name =~ s/\A(?<!\+)/Tit::View::/g;
                my $view = $tit->view($view_name) || $tit->default_view;
                # warn "VIEW: $view | $view_name"; # 321
                # $view = $tit->view("JSON"); # 321
                $res->body( $view->render($tit) ) unless $tit->response->done;
            };

            if ( $@ =~ / \A 404 \b | Text::Xslate: LoadError: Cannot find /x )
            {
                # warn "No template: $@";
                $res->status(404);
                $res->body([ "Not found ", decode("UTF-8", uri_unescape($req->uri->path), Encode::FB_CROAK) ]);
                # $res->body([ "Not found ", $tit->route->action_path ]);
            }
            elsif ( $@ )
            {
                $res->status(500);
                $res->body([ $@ || "Unknown error o_0" ]);
            }

            if ( $res->charset && $res->body && $req->accept ne "JSON" )
            {
                $res->headers([ "Content-Type" => "text/plain; charset=utf-8" ])
                    unless $res->header("content-type");
                #$_ = encode( $res->charset, $_ ) for @{ $res->body };
                $_ = encode( $res->charset, $_, Encode::FB_CROAK|Encode::LEAVE_SRC ) for @{ $res->body };
            }

            if ( $req->accept eq "JSON" )
            {
                #$_ = decode( $res->charset, $_, Encode::FB_CROAK ) for @{ $res->body };
            }

            $res->finalize;
        };

        use Plack::App::File;

        $apps{$tit->package} = builder {
            #enable "Session::Cookie" => # Cookie is the default state
            #    secret => "Data::UUID"->new->create_str,
            #    session_key => $tit->package,
            #    cookie_expires => 60 * 60 * 24 * 180, # This should all be config.
            #    httponly => 2;
            enable "Session" => # Cookie is the default state
                store => "File",
                sid_generator => sub { "Data::UUID"->new->create_str },
                session_key => $tit->package,
                cookie_expires => 60 * 60 * 24 * 180, # This should all be config.
                httponly => 2;

            mount "/favicon.ico" => Plack::App::File->new( file => $tit->home . "/root/static/favicon.ico" )->to_app;
            mount "/img" => Plack::App::File->new( root => $tit->home . "/root/static/img" )->to_app;
            mount "/" => $APP;
        };
    } # to_app

    # Do we just NOT support HEAD?

    my %entity_permitted = map {; $_ => 1 }  # VERY PARTIAL, SEMI-VETTED, NOT SUPPORTED YET.
         ( 200, 201, 202, 203,
           205, 206,
           # Several 300s support them I think…
           301, 302, 303, 307, 308,
           400 .. 510 # All of these have it optional, if I'm correctly informed.
         );

    sub rest {
        require JSON::XS;
        require HTTP::Status;
        state $encoder = JSON::XS->new->pretty->allow_nonref->convert_blessed;

        my $self = shift;
        my $status = shift || croak "Status and URI are required";                                                           
        HTTP::Status::status_message($status) || croak "$status is not a valid HTTP status";
        my $uri = shift; #  || croak "URI is required"; # BY TYPE and IF entity.
        my $entity = shift; # Not required. Must be ref.

        my $response = $self->response;
        $response->headers->clear;
        $response->location($uri);

        $response->status($status);

        if ( $status =~ /\A3/ )
        {
            $response->redirect( $response->location, $status );
        }

        if ( $entity_permitted{$status} and $entity )
        {
            if ( $response->request->accept eq "JSON" )
            {
                $response->content_type("application/json; charset=utf-8");
                # # warn decode("UTF-8", $encoder->encode($entity), Encode::FB_CROAK);
                # $response->body([ $encoder->encode($entity) ]);
                #no warnings "uninitialized";
                #my $title = $entity->title;
                #my $content = decode("UTF-8", $entity->content);
                # warn $content;
                # THIS BACK AND FORTH IS NOT RIGHT…
                # $response->body([ decode("UTF-8", $encoder->encode($entity), Encode::FB_CROAK) ]);
                $response->body([ $encoder->encode($entity) ]);
                # ^^^ REFACTOR!!!!!!!
            }
            elsif ( $self->request->accept eq "Xslate" )
            {
                %{ $self->stash } = %{ $entity };
                # $self->content_type("text/html");
                # Fall through to render?
            }
        }
        else
        {
            croak;
        }
    }

    1;
};

# MAYBE eval these in a meta method or debug mode? Or move them to the
# test stuff. They can't stay as is, in any case.
sub Tit::TO_JSON { +{ %{ +shift } } }
sub Tit::Request::TO_JSON { +{ %{ +shift } } }
sub Tit::Response::TO_JSON { +{ %{ +shift } } }
sub Tit::Route::TO_JSON { +{ %{ +shift } } }
sub Tit::Router::TO_JSON { +{ %{ +shift } } }
sub HTTP::Headers::Fast::TO_JSON { +{ %{ +shift } } }
sub IO::Socket::INET::TO_JSON { ref +shift }
sub Router::R3::TO_JSON { ref +shift }
sub JSON::XS::TO_JSON { ref +shift }


__END__

Should rely on this: https://httpstatuses.com/

=pod

=encoding utf8

=head1 Name

Tit – paridæ, you pervert …a tiny bird of a web app framework.

=head1 Synopsis

This is aE<mdash>currently half-bakedE<mdash>toy framework for
building web applications. If you want a real framework look at
L<Mojolicious>, L<Catalyst>, L<Dancer2>, or similar packages.

See instead the document you really want: L<Tit::Manual>.

=head1 Rationale and Caveat

This is quite a bit like—but much less featureful than—lots of
micro-frameworks. This is probably not what you want. It's alpha
software until this notice is removed and it's raison d'être is
sacrficial animal for a planned successor: Wren. Wren is approximately
as likely as Perl 6 was in 2001 so…

Rationale? I've been doing this a loooooooong time. I'm curious about
how little of it I really need for the things I write and what
applications can look like when stripped down to the essentials. I'm
vain enough to not settle on one of the current microframeworks.

=head1 Interface

See L<Tit::Manual>.

=head1 Methods

Top level objects/classes.

…

=head1 To Do

=over 4

=item Namespaces

Namespace, multi-instance of same app…? Relative URIs based on namespace?

=back

=head2 Tests

=over 4

=item Abuses of interface

Test things like C<get REF, NON-SUB, ARRAY>, etc. The reasonableness
of this package rests on good error feedback. It should be
self-guiding.

Doubling of named models and views.

=item More toys? All of them?

MiniWiki, POD viewer, and Unicode Browser are already slated and the
first two are done/stubbed. L<https://bitbucket.org/pangyre/rfc-toy>.

=back

=head1 Code Repository

L<http://github.com/pangyre/p5-tit>.

=head1 See Also

L<Plack::App::REST>, L<Plack::Middleware::REST>, L<Dancer2>,
L<Mojolicious>, L<Flea>, L<Kelp>, et cetera.

=head1 Author and Copyright

©2019 Ashley Pond V E<middot> ashley@cpan.org.

=head1 License

You may redistribute and modify this package under the same terms as Perl itself.

=head1 Disclaimer of Warranty

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify or
redistribute the software as permitted by the above license, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut

REST "some/route", $config; #?
# instantiates…
…No, right? REST should be an assumption, not an add on.

Not yet

    for my $method ( qw/ OPTIONS GET HEAD POST PUT DELETE TRACE CONNECT /)
    {
        push @EXPORT, my $lc = lc $method;
        eval <<"";
          sub $lc {
              confess "Be serious" if \@_ > 3;
              my \$path = shift;
              my \$code = shift;
              push \@raw_routes, join(" ", $method => \$path), \$code;
          }



