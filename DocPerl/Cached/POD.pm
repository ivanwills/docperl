package DocPerl::Cached::POD;

=head1 NAME

DocPerl::Cached::POD - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to DocPerl::Cached::POD version 0.1.


=head1 SYNOPSIS

   use DocPerl::Cached::POD;

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

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

# Created on: 2006-03-19 20:31:36
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


=head3 C<init ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  - 

Description: 

=cut

sub init {
	my $self	= shift;
	
}

=head3 C<process ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  - 

Description: 

=cut

sub process {
	my $self	= shift;
	
	return $self->pod();
}

=head3 C<pod ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  - 

Description: 

=cut

sub pod {
	my $self	= shift;
	my $conf	= $self->{conf};
	my $module	= $self->{module};
	my $file	= $self->{source} || '';
	my @folders	= $self->{folders};
	my @suffixes;
	
	croak "No location supplied" unless $self->{current_location};
	
	# check that we found the proper file
	return ( pod => "Could not find $self->{module_file} in ".join ", ", @folders )
		if !$file || $file eq $self->{module_file};
	
#	# check the cached version
#	my $pod = $self->_check_cache( cache => "pod/$self->{current_location}/$self->{module_file}", source => $file, );
#	# return the pod if the cache exists and is in date
#	return ( pod => $pod ) if $pod;
	
	# construct the list of parameters
	my @params = (
		"--infile=$file",
		"--podroot=.",
		"--title=$module",
		"--index",
		"--cachedir=$conf->{General}{Data}/cache",
		"--css=?page=css.css"
	);
	my $cmd = "/usr/bin/perl -MPod::Html -e 'pod2html(\"" . join( '", "', @params ) . "\")'";
	
	# Create the HTML POD
	my $pod = `$cmd 2>/dev/null`;
	
	if ( length $pod < 100 ) {
		return ( pod => "Could not create the POD for $module $!\n$pod\n". Dumper \%ENV );
	}
	
	$pod =~ s/\d$//s if $pod =~ /\d$/s;
	$pod =~ s/<\/pre>(\s*)<pre>/$1/img if $1;
	$pod =~ s{href="/}{target="module" href="?type=module&module=link/}gxs;
	
#	$self->_save_cache( cache => "pod/$self->{current_location}/$self->{module_file}", source => $file, content => $pod );
	
	return ( pod => $pod, pwd => `pwd` );
}


1;

__END__
