package DocPerl::View::FUNCTION;

# Created on: 2007-02-13 19:14:27
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

# Created on: 2007-02-13 19:14:27
# Create by:  ivan

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Pod::POM;
use Pod::POM::View::Text;
use base qw/DocPerl::View/;

our $VERSION     = version->new('0.9.0');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub process {
	my $self    = shift;
	my $conf    = $self->{conf};
	my $module  = $self->{module};
	my $file    = $self->{source} || '';
	my @folders = $self->{folders};

	croak 'No location supplied' if !$self->{current_location};

	# check that we found the proper file
	return ( pod => "Could not find $self->{module_file} " . ( !$file ? 'no file' : 'in ' . join ', ', @folders ) )
		if !$file || $file eq $self->{module_file};

	# check $file (for tainting)
	($file)   = $file   =~ m{\A ( [\w\-./]+ ) \Z}xms;
	($module) = $module =~ m{\A ( [\w\:]+ ) \Z}xms;

	return ( pod => "File contains dodgy characters ($file)" ) if !$file;

	my $text;
	open my $fh, '<', $file or carp "Could not open the file '$file': $OS_ERROR\n" and return ( func => 'none' );
	{
		local $/;
		$text = <$fh>;
	}
	my @functions = $text =~ /(?:^|\W)sub \s+ (\w+)/gxms;

	return ( functions => \@functions );
}

1;

__END__

=head1 NAME

DocPerl::View::FUNCTION - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to DocPerl::View::FUNCTION version 0.9.0.


=head1 SYNOPSIS

   use DocPerl::View::FUNCTION;

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


=head3 C<sub ( $search, )>

Param: C<$search> - type (detail) - description

Return: DocPerl::View::FUNCTION -

Description:

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

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut