package DocPerl::POM::HTML;

# Created on: 2007-02-19 20:38:23
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use CGI;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Pod::POM::View::HTML/;

our $VERSION     = version->new('0.9.2');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
our $LOCATION    = 'inc';
our $MODULE      = 'inc';
our $FILE        = 'inc';
our $SOURCE      = 'inc';
our $ANCHORS     = {};

sub menu {
	my ( $self, $pod ) = @_;

	$ANCHORS  = {};
	my $menu  = '<ul class="menu">' . "\n";
	my @items = $self->menu_items($pod);

	for my $item (@items) {
		my $title = $item->title->present($self);
		my $type  = $item->type();
		my ($level) = $type =~ /^head(\d)$/xms;

		$menu .= "\t"
			. '<li class="level'
			. $level
			. '"><a href="#'
			. $self->make_anchor($title) . '">'
			. $title
			. "</a></li>\n";
	}
	$menu .= "</ul>\n";

	return $menu;
}

sub menu_items {
	my ( $self, $pom ) = @_;
	my @items;

	for my $item ( $pom->content() ) {
		my $type = $item->type();
		if ( $type eq 'head1' || $type eq 'head2' || $type eq 'head3' || $type eq 'head4' ) {
			push @items, $item;
			my $title = ref $item->title ? $item->title->present() : $item->title;
			$title =~ s/\s.*$//xms;
			$ANCHORS->{$title} = 1;
		}
		if ( $type eq 'item' ) {
			my $title = ref $item->title ? $item->title->present() : $item->title;
			$title =~ s/\s.*$//xms;
			if ( $title !~ /\A\s*\*\s*/xms && $title !~ /\A\s*\d+\.?\s*/xms ) {
				$ANCHORS->{$title} = 1;
			}
		}
		push @items, $self->menu_items($item);
	}

	return @items;
}

sub make_anchor {
	my ( $self, $title ) = @_;
	my $anchor = lc $title;
	$anchor =~ s/::/__/gxms;
	$anchor =~ s/\s/_/gxms;
	$anchor =~ s/<[^>]*>//gxms;
	return $anchor;
}

sub view_pod {
	my ( $self, $pod ) = @_;
	return '<a name="__top"></a>' . $self->menu($pod) . $pod->content->present($self);
}

sub view_head1 {
	my ( $self, $head1 ) = @_;
	my $title = $head1->title->present($self);
	my ($link) = $title =~ / (?: <[^>]+> )? (\w+) /xms;
	return '<h1><a name="'
		. $self->make_anchor($title)
		. '" href="#__top" title="to top of page">'
		. $title
		. ' <div class="up">&#8593;</div>'
		. '</a> '
		. make_code_href(lc $link)
		. "</h1>\n\n"
		. $head1->content->present($self);
}

sub view_head2 {
	my ( $self, $head2 ) = @_;
	my $title = $head2->title->present($self);
	my ($link) = $title =~ / (?: <[^>]+> )? (\w+) /xms;
	return '<h2><a name="'
		. $self->make_anchor($title)
		. '" href="#__top" title="to top of page">'
		. $title
		. '</a> '
		. make_code_href(lc $link)
		. "</h2>\n\n"
		. $head2->content->present($self);
}

sub view_head3 {
	my ( $self, $head3 ) = @_;
	my $title = $head3->title->present($self);
	my ($link) = $title =~ / (?: <[^>]+> )? (\w+) /xms;
	return '<h3><a name="'
		. $self->make_anchor($title)
		. '" href="#__top" title="to top of page">'
		. $title
		. '</a> '
		. make_code_href(lc $link)
		. "</h3>\n\n"
		. $head3->content->present($self);
}

sub view_head4 {
	my ( $self, $head4 ) = @_;
	my $title = $head4->title->present($self);
	my ($link) = $title =~ / (?: <[^>]+> )? (\w+) /xms;
	return '<h4><a name="'
		. $self->make_anchor($title)
		. '" href="#__top" title="to top of page">'
		. $title
		. '</a> '
		. make_code_href(lc $link)
		. "</h4>\n\n"
		. $head4->content->present($self);
}

sub view_over {
	my ( $self, $over ) = @_;
	my ( $start, $end, $strip );

	my $items = $over->item();
	return q{} if !@{$items};

	my $first_title = $items->[0]->title();

	if ( $first_title =~ /\A\s*\*\s*/xms ) {

		# '=item *' => <ul>
		$start = "<ul>\n";
		$end   = "</ul>\n";
		$strip = qr/^\s*\*\s*/;
	}
	elsif ( $first_title =~ /\A\s*\d+\.?\s*/xms ) {

		# '=item 1.' or '=item 1 ' => <ol>
		$start = "<ol>\n";
		$end   = "</ol>\n";
		$strip = qr/^\s*\d+\.?\s*/;
	}
	else {
		$start = "<dl>\n";
		$end   = "</dl>\n";
		$strip = q{};
	}

	my $overstack = ref $self ? $self->{OVER} : \@SUPER::OVER;
	push @{$overstack}, $strip;
	my $content = $over->content->present($self);
	pop @{$overstack};

	return $start . $content . $end;
}

sub view_item {
	my ( $self, $item ) = @_;

	my $over  = ref $self ? $self->{OVER} : \@SUPER::OVER;
	my $title = $item->title();
	my $strip = $over->[-1];

	my $start_title   = '<li>';
	my $end_title     = q{};
	my $start_content = q{};
	my $end_content   = '</li>';

	if ( defined $title ) {
		if ( ref $title ) {
			$title = $title->present($self);
		}
		if ($strip) {
			$title =~ s/$strip//xms;
		}
		if ( length $title ) {
			my $anchor = $title;
			$anchor =~ s/^\s*|\s*$//gxms;    # strip leading and closing spaces
			$anchor =~ s/\W/_/gxms;
			$title = qq{<a name="item_$anchor"></a><b>$title</b>};
		}
	}

	if ( !$strip ) {
		$start_title   = '<dt>';
		$end_title     = '</dt>';
		$start_content = '<dd';
		$end_content   = '</dd>';
	}

	return "$start_title$title$end_title\n" . $start_content . $item->content->present($self) . "$end_content\n";
}

sub view_seq_code {
	my ( $self, $text ) = @_;

	# check if the text loosk like a Module
	if ( $ANCHORS->{$text} ) {
		$text = "<a href=\"#item_$text\">$text</a>";
	}
	elsif ( $text =~ /^[\w:]+$/xms ) {
		$text = "<a href=\"?page=pod&module=$text&location=$LOCATION\">$text</a>";
	}

	return "<code>$text</code>";
}

sub view_seq_link {
	my ( $self, $link ) = @_;

	# view_seq_text has already taken care of L<http://example.com/>
	if ( $link =~ /^<a href=/xms ) {
		return $link;
	}

	# full-blown URL's are emitted as-is
	if ( $link =~ m{^\w+://}xms ) {
		return make_href($link);
	}

	$link =~ s/\n/ /gxms;    # undo line-wrapped tags

	my $orig_link = $link;
	my $linktext;

	# strip the sub-title and the following '|' char
	if ( $link =~ s/^ ([^|]+) \| //xms ) {
		$linktext = $1;
	}

	# make sure sections start with a /
	$link =~ s{^"}{/"}xms;

	my $page;
	my $section;
	if ( $link =~ m{^ (.*?) / "? (.*?) "? $}xms ) {    # [name]/"section"
		( $page, $section ) = ( $1, $2 );
	}
	elsif ( $link =~ /\s/xms ) {                       # this must be a section with missing quotes
		( $page, $section ) = ( q{}, $link );
	}
	else {
		( $page, $section ) = ( $link, q{} );
	}

	# warning; show some text.
	if ( !defined $linktext ) {
		$linktext = $orig_link;
	}

	my $url = q{};
	if ( defined $page && length $page ) {
		$url = $self->view_seq_link_transform_path($page);
	}

	# append the #section if exists
	if ( defined $url && defined $section && length $section ) {
		$url .= "#$section";
	}

	return make_href( $url, $linktext );
}

sub make_href {
	my ( $url, $title ) = @_;

	if ( !defined $url ) {
		if ( $title =~ /^[\w:]+$/xms ) {
			$url = "?page=pod&module=$title&location=$LOCATION";
		}
		else {
			return defined $title ? "<i>$title</i>" : q{};
		}
	}

	if ( !defined $title ) {
		$title = $url;
	}
	return qq{<a href="$url">$title</a>};
}

sub make_code_href {
	my ($title) = @_;
	my $url = "?page=code&module=$MODULE&file=$FILE&location=$LOCATION&source=$SOURCE#$title";

	return qq{<a href="$url" title="View in code" class="code">C</a>};
}

1;

__END__

=head1 NAME

DocPerl::POM::HTML - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to DocPerl::POM::HTML version 0.9.2.


=head1 SYNOPSIS

   use DocPerl::POM::HTML;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.

These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module
provides.

Name the section accordingly.

In an object-oriented module, this section should begin with a sentence (of the
form "An object of this class represents ...") to give the reader a high-level
context to help them understand the methods that are subsequently described.

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
