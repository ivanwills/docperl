package DocPerl::View::CODE;

# Created on: 2006-03-19 20:32:42
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use Scalar::Util;
use English '-no_match_vars';
use base qw/DocPerl::View/;

our $VERSION   = version->new('1.0.0');
our @EXPORT    = qw//;
our @EXPORT_OK = qw//;

sub process {
	my $self        = shift;
	my $q           = $self->{cgi};
	my $code        = $self->{source};
	my $in_pod      = 0;
	my $here_marker = q{};
	my $here_style;
	my @lines;
	my %links;

	return if !-f $code;

	open my $file, '<', $code or carp "Could not open the file '$code': $!" and return;

	while ( my $line = <$file> ) {

		# convert tabs into spaces of width 4
		my $code_line = to_spaces( $line, 4 );

		my $j = $INPUT_LINE_NUMBER;

		# check if the line contains infor that may be linked to esternally
		if ( my ( $func, $head ) = $line =~ /^(?:\s* sub \s+ (\w+) | =head[1234] \s+ (?:\w<)? (\w+) )/xms ) {
			$links{ lc ( $func || $head ) }{ $func ? 'func' : 'head' } = $j;
		}

		# Quote all special characters
		$code_line =~ s/&/&amp;/gxms;
		$code_line =~ s/</&lt;/gxms;
		$code_line =~ s/>/&gt;/gxms;

		# check if the line we are currently passing is a here doc line
		if ($here_marker) {

			#$code_line = qq{<span class="pod">$code_line}; #$q->start_span( { -class => "pod" } ) . $code_line;
		}

		# check if we are currently processing POD
		if ( $in_pod || $code_line =~ /^=/xms ) {
			$in_pod = $code_line =~ /^=cut/xms ? 0 : 1;
			$code_line = qq{<span class="pod">$code_line};
			if ( !$in_pod ) {
				$code_line .= '</span>';
			}
		}
		elsif ( $code_line and not $here_marker ) {

			# check if the line has a comment
			my ( $code, $char, $comment ) = $code_line =~ /(?:^ | (.*?) ([^\$]) ) # (.*)$/xms;

			# check if the line is that sort of line
			if ( not $code and not $char and not $comment ) {
				$code    = $code_line;
				$char    = q{};
				$comment = q{};
			}
			elsif ($comment) {
				$comment = qq{<span class="comment">#$comment</span>};
			}

			# tag the various parts of perl code
			$code = $code ? $self->tag_code($code) : $code;

			# reassemble the line of code
			$code_line = $code;
			if ($char) {
				$code_line .= $char;
			}
			if ($comment) {
				$code_line .= $comment;
			}
		}

		# Check if the line contains a heredoc reference
		if ( $line and $line =~ /<<(['"])(\w+)\1/xms ) {
			$here_style  = $1;
			$here_marker = $2;
		}

		# close the pod span if one started
		if ($in_pod) {
			$code_line .= q{</span>};
		}

		# mark the line as such
		$code_line = qq{<span class="line">$code_line</span>};
		$code_line =~ s/(?:\r?\n)+//gxms;

		# check if the here doc has ended
		if ( $here_marker and $line and $line =~ /^$here_marker/xms ) {
			$here_marker = undef;
		}

		# add the line to the array
		push @lines, { line_no => $j, code => $code_line };
	}

	close $file or carp "Problem in closing file handle: $OS_ERROR\n";
	for my $link ( keys %links ) {
		$lines[ ($links{$link}{func} || $links{$link}{head}) - 3 ]{ext_link} = $link;
	}

	return lines => \@lines;
}

sub tag_code {
	my ( $self, $code ) = @_;

	# tag operators
	$code =~ s/(=~?|\.=|\|\|=|\*=|\\=|\+=|-=|\|\|?|&amp;(?:&amp;)?|<=>)/<span class="operator">$1<\/span>/gxms;

	# tag string operators
	$code =~ s/([^\w&])(eq|ne|le|ge|lt|gt|cmp)(\W)/$1<span class="operator">$2<\/span>$3/gxms;

	# tag operators missed by other re's
	$code =~ s/([^-])(&lt;|&gt;)/$1<span class="operator">$2<\/span>/gxms;

	# tag reserved words
	$code =~ s/(\W|^)(if|else|elsif|unless|while|do|for|foreach|sub|return|my|our|local|use|require|no)(\W|$)/$1<span class="reserved">$2<\/span>$3/gxms;

	# tag built-in functions
	$code =~ s/(\W|^)(shift|warn|die|exit|print|open|close|exists|defined)(\(|\s)/$1<span class="builtin">$2<\/span>$3/gxms;

	# tag built-in functions
	$code =~ s/(\W|^)(sort|keys|values|unlink|push|pop|shift|unshift)(\(|\s)/$1<span class="builtin">$2<\/span>$3/gxms;

	# tab variable declarations
	$code =~ s/(\W|^)(my|our|local)(\W)/$1<span class="declatory">$2<\/span>$3/gxms;

	# tag loop operators
	$code =~ s/(\W)(next|last|exit)(\W|$)/$1<span class="other">$2<\/span>$3/gxms;

	# tag logical opperators
	$code =~ s/(\s)(not|or\s+not|or|and\s+not|and)(\s)/$1<span class="logic">$2<\/span>$3/gxms;
	$code =~ s/(->|\s)(new)(\(|\s)/$1<span class="builtin">$2<\/span>$3/gxms;

	return $code;
}

sub to_spaces {
	my ( $line, $tab_size ) = @_;

	# only do the check if there are tabs
	return $line if $line !~ /\t/xms;
	my $spaces = q{ } x $tab_size;
	return $spaces if $line eq "\t";

	# remove any initial spaces
	while ( $line =~ /^(\s*)\t/xms ) {
		$line =~ s/^(\s*)\t/$1$spaces/gxms;
	}

	# split the line into tabs
	my @parts = split /\t/xms, $line;
	if ( $line =~ /^\t/xms ) {
		unshift @parts, q{};
	}
	my $final = ( $line =~ /\t$/xms ) ? 1 : 0;
	$line = q{};

	for my $i ( 0 .. $#parts ) {
		my $part = $parts[$i];
		if ( !$part ) {
			$line .= $spaces;
			next;
		}
		$line .= $part;
		if ( $i != $#parts or $final ) {
			$line .= q{ } x ( 4 - length($part) % $tab_size );
		}
	}
	return $line;
}

1;

__END__

=head1 NAME

DocPerl::View::CODE - Displays the code of a specified file in syntax highlighted HTML

=head1 VERSION

This documentation refers to DocPerl::View::CODE version 1.0.0.

=head1 SYNOPSIS

   use DocPerl::View::CODE;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

This module displays the code of a specified file in HTML with line numbers and
some syntax high lighting.

=head1 SUBROUTINES/METHODS

=head2 C<process ( )>

Return: HASH - The processed code lines as HTML

Description: Converts the source file to HTML for display

=head2 C<tag_code ( $code )>

Param: $code - string - The line of code that is to have HTML tags applied

Return: string - The code with HTML tags applied

Description: Applies HTML tags to sections of the code

=head2 C<to_spaces ( $line, $tab_size )>

Param: $line - The line with tabs that are to be converted into spaces

Param: $tab_size - The size that tabs are assumed to be

Return: string - The line with tabs converted into spaces

Converts one line of text from using tabs of size $tab_size to using spaces

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

This module uses a very simple syntax highlighting scheme relying only on
regular expressions, the generated html may not be that well hightlighted.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
