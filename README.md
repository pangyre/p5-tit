# Name

Tit – paridæ, you pervert …a tiny bird of a web app framework.

# Synopsis

This is a—currently half-baked—toy framework for
building web applications. If you want a real framework look at
[Mojolicious](https://metacpan.org/pod/Mojolicious), [Catalyst](https://metacpan.org/pod/Catalyst), [Dancer2](https://metacpan.org/pod/Dancer2), or similar packages.

See instead the document you really want: [Tit::Manual](https://metacpan.org/pod/Tit::Manual).

# Rationale and Caveat

This is quite a bit like—but much less featureful than—lots of
micro-frameworks. This is probably not what you want. It's alpha
software until this notice is removed and it's raison d'être is
sacrficial animal for a planned successor: Wren. Wren is approximately
as likely as Perl 6 was in 2001 so…

Rationale? I've been doing this a loooooooong time. I'm curious about
how little of it I really need for the things I write and what
applications can look like when stripped down to the essentials. I'm
vain enough to not settle on one of the current microframeworks.

# Interface

See [Tit::Manual](https://metacpan.org/pod/Tit::Manual).

# Methods

Top level objects/classes.

…

# To Do

- Namespaces

    Namespace, multi-instance of same app…? Relative URIs based on namespace?

## Tests

- Abuses of interface

    Test things like `get REF, NON-SUB, ARRAY`, etc. The reasonableness
    of this package rests on good error feedback. It should be
    self-guiding.

    Doubling of named models and views.

- More toys? All of them?

    MiniWiki, POD viewer, and Unicode Browser are already slated and the
    first two are done/stubbed. [https://bitbucket.org/pangyre/rfc-toy](https://bitbucket.org/pangyre/rfc-toy).

# Code Repository

[http://github.com/pangyre/p5-tit](http://github.com/pangyre/p5-tit).

# See Also

[Plack::App::REST](https://metacpan.org/pod/Plack::App::REST), [Plack::Middleware::REST](https://metacpan.org/pod/Plack::Middleware::REST), [Dancer2](https://metacpan.org/pod/Dancer2),
[Mojolicious](https://metacpan.org/pod/Mojolicious), [Flea](https://metacpan.org/pod/Flea), [Kelp](https://metacpan.org/pod/Kelp), et cetera.

# Author and Copyright

©2019 Ashley Pond V · ashley@cpan.org.

# License

You may redistribute and modify this package under the same terms as Perl itself.

# Disclaimer of Warranty

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
