package DocPerl::Cached::CODE;

=head1 NAME

DocPerl::Cached::CODE - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to DocPerl::Cached::CODE version 0.1.


=head1 SYNOPSIS

   use DocPerl::Cached::CODE;

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

=cut

# Created on: 2006-03-19 20:32:42
# Create by:  ivan

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use Scalar::Util;
use base qw/DocPerl::Cached/;

our $VERSION = version->new('0.0.1');
our @EXPORT = qw//;
our @EXPORT_OK = qw//;


=head3 C<process ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  - 

Description: 

=cut

sub process {
	my $self		= shift;
	my $q			= $self->{cgi};
	my $code		= $self->{source};
	my $in_pod		= 0;
	my $here_marker	= '';
	my $here_style;
	my @lines;
	
	open my $file, '<', $code or warn "Could not open the file '$code': $!" and return [];
	
	while ( my $line = <$file> ) {
		# convert tabs into spaces of width 4
		my $code_line = to_spaces( $line, 4 );
		
		my $j         = $.;
		my $line_no   = qq{<a name="line$j" class="line_no"> $j </a> };# $q->a( { -name => "line$j", -class => "line_no" }, " $j " ) . "  ";
		
		# Quote all special characters
		$code_line =~ s/&/&amp;/gxs;
		$code_line =~ s/</&lt;/gxs;
		$code_line =~ s/>/&gt;/gxs;
		
		# check if the line we are currently passing is a here doc line
		if ( $here_marker ) {
			#$code_line = qq{<span class="pod">$code_line}; #$q->start_span( { -class => "pod" } ) . $code_line;
		}
		
		# check if we are currently processing POD
		if ( $in_pod || $code_line =~ /^=/ ) {
			$in_pod = $code_line =~ /^=cut/ ? 0 : 1;
			$code_line = qq{<span class="pod">$code_line}; #$q->start_span( { -class => "pod" } ) . $code_line;
		}
		elsif ( $code_line and not $here_marker ) {
			# check if the line has a comment
			my ( $code, $char, $comment ) = $code_line =~ /(?:^ | (.*?) ([^\$]) ) # (.*)$/xs;
			
			# check if the line is that sort of line
			if ( not $code and not $char and not $comment ) {
				$code    = $code_line;
				$char    = '';
				$comment = '';
			}
			elsif ($comment) {
				$comment = qq{<span class="comment">#$comment</span>}; #$q->span( { -class => "comment" }, "#$comment" );
			}
			
			# tag the various parts of perl code
			if ($code) {
				# tag opperators
				$code =~ s/(=~?|\.=|\|\|=|\*=|\\=|\+=|-=|\|\|?|&amp;(?:&amp;)?|<=>)/<span class="operator">$1<\/span>/gxs;
				# tag string opperators
				$code =~ s/([^\w&])(eq|ne|le|ge|lt|gt|cmp)(\W)/$1<span class="operator">$2<\/span>$3/gxs;
				# tag opperators missed by other re's
				$code =~ s/([^-])(&lt;|&gt;)/$1<span class="operator">$2<\/span>/gxs;
				# tag reserved words
				$code =~ s/(\W|^)(if|else|elsif|unless|while|do|for|foreach|sub|return|my|our|local|use|require|no)(\W|$)/$1<span class="reserved">$2<\/span>$3/gxs;
				# tag builtin functions
				$code =~ s/(\W|^)(shift|warn|die|exit|print|open|close|exists|defined)(\(|\s)/$1<span class="builtin">$2<\/span>$3/gxs;
				# tag builtin functions
				$code =~ s/(\W|^)(sort|keys|values|unlink|push|pop|shift|unshift)(\(|\s)/$1<span class="builtin">$2<\/span>$3/gxs;
				# tab variable declerations
				$code =~ s/(\W|^)(my|our|local)(\W)/$1<span class="declatory">$2<\/span>$3/gxs;
				# tag loop operators
				$code =~ s/(\W)(next|last|exit)(\W|$)/$1<span class="other">$2<\/span>$3/gxs;
				# tag logical opperators
				$code =~ s/(\s)(not|or\s+not|or|and\s+not|and)(\s)/$1<span class="logic">$2<\/span>$3/gxs;
				$code =~ s/(->|\s)(new)(\(|\s)/$1<span class="builtin">$2<\/span>$3/gxs;
			}
			
			# reassemble the line of code
			$code_line = $code;
			$code_line .= $char    if $char;
			$code_line .= $comment if $comment;
		}
		
		# Check if the line contains a heredoc reference
		if ( $line and $line =~ /<<(['"])(\w+)\1/ ) {
			$here_style  = $1;
			$here_marker = $2;
		}
		
		# close the pod span if one started
		if ( $in_pod ) {
			$code_line .= qq{</span>}; #$q->end_span();
		}
		
		# mark the line as such
		$code_line = qq{<span class="line">$code_line</span>}; #$q->span( { -class => "line" }, $code_line );
		$code_line =~ s/(?:\r?\n)+//gxs;
		
		
		# check if the here doc has ended
		if ( $here_marker and $line and $line =~ /^$here_marker/ ) {
			$here_marker = undef;
		}
		
		# add the line to the array
		push @lines, "$line_no$code_line";
	}
	
	close $file;
	
	return lines => \@lines;
}

=head2 C<to_spaces ( $line, $tab_size )>

Param: $line - The line with tabs that are to be converted into spaces

Param: $tab_size - The size that tabs are assumed to be

Return: string - The line with tabs converted into spaces

Converts one line of text from using tabs of size $tab_size to using spaces

=cut

sub to_spaces {
	my ( $line, $tab_size ) = @_;

	# only do the check if there are tabs
	return $line unless $line =~ /\t/;
	my $spaces = " " x $tab_size;
	return $spaces if $line eq "\t";

	# remove any initial spaces
	$line =~ s/^(\s*)\t/$1$spaces/gxs while ( $line =~ /^(\s*)\t/ );

	# split the line into tabs
	my @parts = split /\t/, $line;
	unshift @parts, '' if $line =~ /^\t/;
	my $final = ( $line =~ /\t$/ ) ? 1 : 0;
	$line = '';

	for ( my $i = 0 ; $i < @parts ; $i++ ) {
		my $part = $parts[$i];
		unless ($part) {
			$line .= $spaces;
			next;
		}
		$line .= $part;
		$line .= " " x ( 4 - length($part) % $tab_size ) if $i != $#parts or $final;
	}
	return $line;
}


1;

__END__

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
