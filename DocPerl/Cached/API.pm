package DocPerl::Cached::API;

=head1 NAME

DocPerl::Cached::API - Inspects a perl file to find what functions are defined
modules used/inherited etc

=head1 VERSION

This documentation refers to DocPerl::Cached::API version 0.6.0.


=head1 SYNOPSIS

  use DocPerl::Cached::API;
  
  # Create a new API variable
  my $api = DocPerl::Cached::API->new(
      conf    => {
          General      => {
              Data     => '/tmp/',
          },
          IncFolders   => {
              Path     => '',
          },
      },
      source => $file,
      current_location => '',
  );
  
  # get a hash ref with the information about the API found
  my $description = $api->process();
  
  # $description will contain something like
  # {
  #   api => {
  #      modules   => [a list of modules used],
  #      parents   => [a list of modules directly inhreited from],
  #      required  => [a list of modules required],
  #      vars      => [a list of package variable defined],
  #      version   => 'File version number',
  #      class     => [
  #          { name => 'class method', line => 'line no method defined on' }, ...
  #      ],
  #      object    => [
  #          { name => 'method', line => 'line no method defined on' }, ...
  #      ],
  #      func      => [
  #          { name => 'function', line => 'line no defined' }, ...
  #      ],
  #      hirachy   => [ inverted definition of class hirachy ],
  #   }
  # };

=head1 DESCRIPTION

This module inspects perl files and tries to determine what subroutines/
object methods/class methods and package variables are defined as well as
the module use()ed, require()d and inherited from.

=head1 SUBROUTINES/METHODS

=cut

# Created on: 2006-03-19 20:32:12
# Create by:  ivan

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use Scalar::Util;
use base qw/DocPerl::Cached/;

our $VERSION = version->new('0.6.0');
our @EXPORT = qw//;
our @EXPORT_OK = qw//;

=head3 C<display ( )>

Return: HASHREF - The files API

Description: Processes a file to find out what modules it uses, what subs it
declares (and weather they are class or object methods or plain subs) and the
inheritance tree if any of the module.

=cut

sub process {
	my $self	= shift;
	my $conf	= $self->{conf};
	my $location= $self->{current_location};
	my $source	= $self->{source} || '';
	my $file	= $source;
	
	return unless -f $file;
	
	# open the file
	open my $fh, '<', $file or warn "Cannot open $file: $!\n" and return;
	my %api = ( pod => 0, parents => [] );
	my $i   = 0;
	my $pod = 0;
	my $end = 0;
	
	# loop through the file line by line
	LINE:
	while ( my $line = <$fh> ) {
		$i++;
		
		if ( $line =~ /^=(\w*)/ || $pod ) {
			$api{pod}++;
			my $pod_cmd = $1;
			$pod = $pod && $pod_cmd eq 'cut' ? 0 : 1;
			next LINE;
		}
		
		# ignore lines starting with a {, } or #
		next LINE if $line =~ /^\s* (?: (?: (?: [{] | [}] ) \s* $ ) | [#] )/xs;
		
		# check if we have reached the end of the file
		$end = 1 if $line =~ /^__(END|DATA)__/;
		# lines after the end/data can only add to POD stat
		next LINE if $end;
		
		# if the line starts with the package directive
		if ( $line =~ /^\s*package ([\w:]+);/ ) {
			if ( $api{package} ) {
				push @{ $api{packages} }, $1;
			}
			else {
				$api{package} = $1;
			}
		}
		
		# check if the line starts with 'use base' to indicate inhereted packages
		elsif ( $line =~ m#^
							\s* use \s+ base \s+ qw
							( [\|/({\[] )
							\s*([\w:]+)\s*
							( [\|/)}\]] )
							#xm ) {
			my $parents = $2;
			my @parents = split /\s+/, $parents;
			push @{ $api{parents} }, @parents;
		}
		
		# check if the line starts with '@ISA' to indicate inhereted packages
		elsif ( $line =~ / \@ISA \s* = \s* \( ([^)]+) \)  /x ) {
			my $parents = $1;
			my @parents = split /,\s*/, $parents;
			$_ =~ s/'|\s//g for (@parents);    #'
			push @{ $api{parents} }, @parents;
		}
		elsif ( $line =~ m#^
							\s* \@ISA \s* = \s* qw
							(?: [|] | [/] | [(] | [{] | \[ )
							\s*(.*)\s*
							(?: [|] | [/] | [)] | [}] | \] )
							#xm ) {
			#warn "Untested!!!!!!!!!";
			my $parents = $1;
			my @parents = split /\s+/, $parents;
			push @{ $api{parents} }, @parents;
		}
		elsif ( $line =~ / push \s* [(]? \s* \@ISA \s* , \s* (?:['"])? ([\w:]+) (?:['"])? /x ) {
			my $parents = $1;
			my @parents = split /,\s*/, $parents;
			push @{ $api{parents} }, @parents;
		}
		
		# check for generic module 'use'
		elsif ( my ($module) = $line =~ /^\s*use\s+([\w:]*)/ ) {
			$api{modules}{$module}++;
		}
		
		# check for generic module 'require'
		elsif ( my ($require) = $line =~ /^\s*require\s+([\w:]*)/ ) {
			$api{required}{$require}++;
		}
		
		# check for package variables
		elsif ( my ($var) = $line =~ /^\s*our\s+([\$\%\@]\w+)/xs ) {
			$api{vars}{$var} = $.;
		}
		
		# check for sub directives
		elsif ( my ($func) = $line =~ /^\s*sub\s+(\w+)/ ) {
			my $method     = 0;
			my $found_line = $i;
			my $line;
			for ( my $sub_line_no = 0 ; $sub_line_no < 10 and $line = <$fh> ; $sub_line_no++ ) {
				$i++;
				if ( my ($require) = $line =~ /require\s+([\w:]*)/ ) {
					$api{required}{$require}++;
				}
				
				# if the line is of the from $self = shift then assume sub is a method
				if ( $line =~ /}/ ) {
					$sub_line_no = 11;
				}
				
				# if the line is of the form $class = shift or $caller = shift assume sub is a class method
				elsif ( $line =~ /\$(class|caller)\s*=\s*shift;/ ) {
					$api{class}{$func} = $found_line;
					$method = 1;
				}
				
				# stop if we come accross a closing bracket
				elsif ( $line =~ /\$(self|this)\s*=\s*shift;/ ) {
					$api{object}{$func} = $found_line;
					$method = 1;
				}
				
				# alternate object opener $this = shift form
				elsif ( $line =~ /my\s*\(\s*\$(self|this)[^\)]*\)\s*=\s*\@_;/ ) {
					$api{object}{$func} = $found_line;
					$method = 1;
				}
				
			}
			
			# if no a class or object method add to functions
			$api{func}{$func} = $found_line unless $method;
		}
	}
	close $fh;
	
	delete $api{parents} unless @{ $api{parents} };
	my @paths = split /:/, $location eq 'local' ? $conf->{LocalFolders}{Path} : $conf->{IncFolders}{Path};
	my $last = @INC - 1;
	push @INC, @paths;
	
	if ( $api{package} ) {
		$api{version} = eval("require $api{package};\$$api{package}\:\:VERSION");
		warn $@ if $@;
		eval {
			$api{hirachy} = [ get_hirachy( $api{package} ) ];
		};
		if ( $@ ) {
			warn $@;
			$api{hirachy} = $api{parents};
		}
		elsif ( !@{ $api{hirachy}[0]{hirachy} } && $api{parents} ) {
			warn "Found parents but not hirachy!";
			$api{hirachy}[0]{hirachy} = [ map {{ class => $_ }} @{$api{parents}} ];
		}
	}
	if ( ref $api{modules} ) {
		$api{modules} = [ sort keys %{ $api{modules} } ];
	}
	for my $type ( qw/class object func vars/ ) {
		if ( ref $api{$type} ) {
			$api{$type} = [ map { { name => $_, line => $api{$type}{$_} } } sort keys %{ $api{$type} } ];
		}
	}
	@INC = @INC[0 .. $last];
	
	return ( api => \%api );
}

=head3 C<get_hirachy ( $object )>

Param: C<$object> - The name of the module who's hirachy is desired

Return: HASHREF - That describes the object hirachy of $object

Description: This function finds out the object hirachy of the passed object
$object by using the object (use $object) and looking at it's ISA array. (it
then cascades down to the next level etc).

=cut

sub get_hirachy {
	my ( $object ) = @_;
	my @hirachy;
	my @parents = eval("\@$object\:\:ISA");
	warn $@ if $@;
	
	foreach my $parent ( @parents ) {
		eval("require $parent");
		if ( !$@ ) {
			push @hirachy, get_hirachy( $parent );
		}
		else {
			push @hirachy, { class => $parent };
		}
	}
	
	return { class => $object, hirachy => \@hirachy };
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

There are no known bugs in this module.

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
