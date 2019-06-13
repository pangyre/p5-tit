use utf8;

package MiniWiki v0.0.1 {
    use parent "Tit";
    use Tit;
    use Path::Tiny;
    use strictures;
    use Carp;
    use Encode; # SHOULD NOT BE HERE.
    require Tit::REST;

    my $db = path( File::Spec->tmpdir, "miniwiki.sqlite" );
    warn "DB -> ", $db;
    add_model DB => "MiniWiki::Schema",
        -adaptor => "DBIC",
        # "dbi:SQLite::memory:",
        "dbi:SQLite:$db",
        { RaiseError => 1,
          AutoCommit => 1,
          ChopBlanks => 1,
          sqlite_unicode => 1 };

    require MiniWiki::Marks;
    add_view Xslate => "Xslate", # NEED TO TRACK THESE TO STDERR/DEBUG TOO.
        path => [ path( $tit->home, "root" ) ],
        module => ['Text::Xslate::Bridge::Star'],
        function => {
            marks => sub { MiniWiki::Marks::render(+shift, $tit) },
        };

    add_view JSON => "JSON"; # NEED TO TRACK THESE TO STDERR/DEBUG TOO.
    # Dislike the redundancy and potential name confusion…

    get "" => sub {
        $tit->stash->{title} = "Pages";
        $tit->stash->{pages} = [ $tit->model("DB::Page")->search({}, { order_by => "title COLLATE NOCASE" })->all ];
        1;
    };

    get "routes" => sub {};
    # get "routes"; # <- SHOULD be legal.

    get "search/{q}" => sub {
        my $q = $tit->stash->{q} = +shift->{q};
        my $rs = $tit->model("DB::Page");
        $tit->stash->{total_pages} = $rs->count;
        $rs = $rs->search({ -or => [ title => { -like => '%' . $q . '%' },
                                     content => { -like => '%' . $q . '%' } ] });
        $tit->stash->{pages} = [ $rs->hashref_rs->all ];
    };

    post "search" => sub {
        my $q = $tit->request->body_parameters->get("q");
        $tit->response->redirect( $tit->uri_for_route("search/*", [$q]) );
    };

    get "random" => sub {
        my $rs = $tit->model("DB::Page")
            ->search({}, { order_by => "RANDOM()" });
        my $page = $rs->first;
        return $tit->response->redirect( $tit->uri_for_route("page/*", [ $page->title ]), 302 )
            if $page;
        $tit->visit("/");
        $tit->response->status(404);
        $tit->stash->{template} = "index.tx";
    };

    get "page" => sub {
        $tit->stash->{title} = $tit->flash("title");
        $tit->stash->{template} = "page/new.tx";
        warn "GOT HERE";
    }, "Xslate"; # Keep for now to check drift/regressions.

    get "page/new/{title}" => sub {
        $tit->flash( title => +shift->{title} );
        # My, what a lucky coincidence of vocabulary domains…
        # THAT space is tricky, need to think it over.
        # $tit->response->body([ $tit->session ]);
        # $tit->session->set( title => +shift->{title} );
        $tit->response->redirect( $tit->uri_for_route("page"), 307 );
    };

    get "page/{title}" => sub {
        my $arg = shift;
        $tit->stash->{page} = $tit->model("DB::Page")->find($arg->{title})
            or die "404";
    }; # VIEW should be REST. ¿Que no?

    get "page/{title}/rest" => sub {
        my $title = +shift->{title};
        my $page = $tit->model("DB::Page")->find($title);
        $tit->response->rest(200,
                             $tit->uri_for_route("page/*/rest", [$title]),
                             $page );
    };

    del "page/{title}" => sub {
        my $title = +shift->{title};
        my $page = $tit->model("DB::Page")->find($title) || die "404\n";
        my %page = $page->get_columns;
        $page->delete;
        if ( $tit->request->accept eq "JSON" )
        {
            $tit->stash->{$_} = $page{$_} for keys %page;# {page} = $page;
        }
        else
        {
            $tit->response->redirect( $tit->uri_for_route("/"), 303 ); # 410 to self?
        }
    };

    # NEED to DELETE param $title if URI $title differs, right?
    put "page/{title}" => sub {
        use JSON::XS;
        my $title = +shift->{title}; # URI is authority.
        my $data = $tit->request->data;
        my $page = $tit->model("DB::Page")->find_or_new({ title => $title });
        $page->title($data->{title}) if $data->{title};
        $page->content($data->{content});

        my $modified = $page->get_dirty_columns;
        my $status = ! $page->in_storage ? 201 :
            $modified ? 303 : 304;
        # Created || See Other || Not Modified.

        $page->in_storage ? $page->update : $page->insert;

        #return [ $status, [], [ encode_json($page->TO_JSON) ] ];
        #my $new_title = $data->{title} || "";
        #die "404\n" unless $page;
        #$page->content($data->{content});
        # Negotiation should decide how this response is formed.
        # $tit->stash->{page} = $page;
        $tit->rest( $status,
                    $tit->uri_for_route("page/*", [$page->title]),
                    { page => $page } );
    };

    get "page/{title}/edit" => sub {
        my $arg = shift;
        # Right idea, not there in the arg swap, differs from the URI construction a bit
        # $tit->response->body([ $tit->visit("page/*", [$arg->{title}]) ]);
        # $tit->visit(page/{title})??? Could send through router, right?
        $tit->stash->{page} = $tit->model("DB::Page")->find($arg->{title})
            or die "404 : $arg->{title}";
    };

    get "page/{title}/delete" => sub {
        my $arg = shift;
        # Right idea, not there in the arg swap, differs from the URI construction a bit
        # $tit->response->body([ $tit->visit("page/*", [$arg->{title}]) ]);
        # $tit->visit(page/{title})??? Could send through router, right?
        $tit->stash->{page} = $tit->model("DB::Page")->find($arg->{title})
            or die "404 : $arg->{title}";
    };

    #get "page/{title}/new" => sub {
    #}, "Xslate"; # Keep for now to check drift/regressions.
    # ^^^ Not particularly good design, at odds with the "title" form field.

    post "page" => sub {
        my $title = $tit->request->body_parameters->get("title");
        my $content = $tit->request->body_parameters->get("content");
        my $page = $tit->model("DB::Page")->create({ title => $title,
                                                     content=> $content });

        $tit->response->redirect( $tit->uri_for_route("page/*", [$title]), 301 );
    };

    1;
};

__END__

=pod

=head1 Name

MiniWiki - a test toy app with L<Tit>.

=head1 Synopsis

 plackup -Ilib -It/lib -MMiniWiki -e "MiniWiki->to_app"

 plackup -Ilib -It/lib -e "use MiniWiki; MiniWiki->to_app" -R t/lib,lib

See L<t/bin/min-wiki.psgi>. Maybe pull this…?

=head1 Code Repository

L<http://github.com/pangyre/>.

=head1 See Also

=head1 Author

Ashley Pond V E<middot> MISSING-EMAIL@gmail.com E<middot> L<http://pangyresoft.com>.

=head1 License

See L<Tit>.

=cut

        $body = ref $body eq "ARRAY" ? $body->[0]
            : ref $body eq "HASH" ? $body->{content}
            : encode("UTF-8", $tit->request->content, Encode::FB_CROAK);
