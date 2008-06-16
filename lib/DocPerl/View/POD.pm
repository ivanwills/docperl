package DocPerl::View::POD;

# Created on: 2007-02-13 19:14:27
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Pod::POM;
use DocPerl::POM::HTML;
use base qw/DocPerl::View/;

our $VERSION     = version->new('1.0.0');
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
	($module) = $module =~ m{\A ( [\w\:.-]+ ) \Z}xms;

	return ( pod => "File contains dodgy characters ($file)" ) if !$file;

	my $parser = $self->parser;
	my $pom = $parser->parse($file);
	my $out;
	{
		local $DocPerl::POM::HTML::LOCATION = $self->{current_location};
		local $DocPerl::POM::HTML::MODULE   = $module;
		local $DocPerl::POM::HTML::FILE     = $self->{module_file};
		local $DocPerl::POM::HTML::SOURCE   = $file;
		$out = DocPerl::POM::HTML->print($pom);
	}

	if ( defined $out ) {
		$out =~ s{</pre>(\s+)<pre>}{$1}gxms;
	}

	return ( pod => $out );
}

sub parser {

	my $self = shift;

	return $self->{parser} if $self->{parser};

	return $self->{parser} = Pod::POM->new( { warn => 0, } );
}

1;

__END__

=head1 NAME

DocPerl::View::POD - Processes a perl file or module to extract its POD

=head1 VERSION

This documentation refers to DocPerl::View::POD version 1.0.0.

=head1 SYNOPSIS

   use DocPerl::View::POD;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<process ()>

Return: HASH - parameters for parsing to a template inparticular the pod key
contains the html generated from the moudules POD.

Description: Process a file to extract its POD documentation. The
file/module whoes POD is to be processed is found from the DocPerl::View::POD
object itself.

=head2 C<parser ()>

Return: Pod::POM - a new or cached Pod::POM object

Description: Caches the internal Pod::POM object

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
