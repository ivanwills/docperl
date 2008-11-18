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

our $VERSION     = version->new('1.1.0');
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

			# fix for perlfunc functions which require at least one param
			if (($MODULE eq 'pod::perlfunc' || $MODULE eq 'perlfunc') && $title =~ /\s/) {
				my $short_anchor = $title;
				$short_anchor =~ s/^ ( \S+ ) \s (?: .* ) $/$1/xms;
				$title = qq{<a name="item_$short_anchor">$title</a>};
			}

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
	if ( $link =~ /^<a \s+ href=/xms ) {
		return $link;
	}

	# try to extract the link title
	my ($link_title, $link_end) = $link =~ /^ (?: ( [^|]* ) [|] )? ( .* ) $/xms;

	# determine the link type
	my $link_type =
		  $link_end =~ m{\A \w+ : [^:\s] \S* \z} ? 'url'
		: $link_end =~ m{\( \d+ \) (?: \Z | / )} ? 'man'
		:                                          'pod';

	my ($link_name, $link_section);

	if ($link_type ne 'url') {
		# for non url links get the link section and name
		($link_section) = $link_end =~ m{ / ['"]? ( .* ) ['"]? $}xms;
		($link_name )   = $link_end =~ m{^ ( [^/]* ) }xms;
	}
	else {
		$link_name = $link_end;
	}

	# set the link title if not given
	$link_title =
		   !$link_title && $link_name && $link_section ? qq{"$link_section" in $link_name}
		 : !$link_title && $link_name                  ? $link_name
		 : !$link_title && $link_section               ? qq{"$link_section"}
		 :                                               $link_title;

	# add the pod prefix to any names starting with perl
	if ($link_name =~ /^perl/) {
		$link_name = "pod::$link_name";
	}

	my $url =
		  $link_type eq 'pod' ? "?page=pod&module=$link_name&location=$LOCATION"
		:                       $link_name || '';

	# append the section to the url if one exists
	if ($link_section) {
		# transform the section to something html safe
		$link_section =~ s/[A-Z] < ( [^>]* ) >/$1/gxms;
		$link_section =~ s/\W/_/gxms;

		# add it to the url
		$url .= "#$link_section";
	}

	return make_href( $url, $link_title );
}

# this code has been borrowed from Pod::Html via Pod::POM::View::HTML
my $urls = '(' . join(
	'|',
	qw{
		http
		telnet
		mailto
		news
		gopher
		file
		wais
		ftp
		}
) . ')';
my $ltrs = '\w';
my $gunk = '/#~:.?+=&%@!\-';
my $punc = '.:!?\-;';
my $any  = "${ltrs}${gunk}${punc}";

{
	my $HTML_PROTECT;

	sub view_begin {
		my ($self, $begin) = @_;
		$HTML_PROTECT++;
		my $out = $self->SUPER::view_begin($begin);
		$HTML_PROTECT--;

		return $out;
	}

	sub view_seq_text {
		my ( $self, $text ) = @_;

		unless ($HTML_PROTECT) {
			for ($text) {
				s/&/&amp;/g;
				s/</&lt;/g;
				s/>/&gt;/g;
			}
		}

		# check that this is not just a label plus URL
		if ( $text =~ / \| $urls : (?!:) [$any]+ $/xms ) {
			# extract the label and url
			my ($label, $url) = split /\|/, $text;

			# return the anchor tag
			return qq{<a href="$url">$label</a>};
		}

		$text =~ s{
			\b                          # start at word boundary
			(                           # begin $1  {
				$urls     :             # need resource and a colon
				(?!:)                   # Ignore File::, among others.
				[$any] +?               # followed by one or more of any valid
										#   character, but be conservative and
										#   take only what you need to....
			)                           # end   $1  }
			(?=                         # look-ahead non-consumptive assertion
					[$punc]*            # either 0 or more punctuation followed
					(?:                 #   followed
						[^$any]         #   by a non-url char
						|               #   or
						$               #   end of the string
					)                   #
				|                       # or else
					$                   #   then end of the string
			)
		}{<a href="$1">$1</a>}igox;

		return $text;
	}
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

This documentation refers to DocPerl::POM::HTML version 1.1.0.


=head1 SYNOPSIS

   use DocPerl::POM::HTML;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

The following methods are modified versions of L<Pod::POM>'s HTML view.

=over 4

=item make_anchor

=item make_code_href

=item make_href

=item menu

=item menu_items

=item view_head1

=item view_head2

=item view_head3

=item view_head4

=item view_item

=item view_over

=item view_pod

=item view_seq_code

=item view_seq_link

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

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
