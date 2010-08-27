use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => 'DocPerl',
	license           => 'perl',
	dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
	dist_version_from => 'lib/DocPerl.pm',
	requires          => {
		'perl'                         => 5.008,
		'Class::Date'                  => '1.1.7',
		'Config::Std'                  => 0,
		'Clone'                        => '0.17',
		'Data::Merger'                 => 0,
		'List::MoreUtils'              => 0,
		'Pod::POM'                     => 0,
		'Pod::POM::View::Text'         => 0,
		'Readonly'                     => 0,
		'Template'                     => '2.14',
		'Template::Provider::FromDATA' => '0.08',
		'version'                      => 0,
	},
	build_requires => {
		'Test::More'       => 0,
		'Test::NoWarnings' => 0,
	},
	add_to_cleanup     => [ 'DocPerl-*' ],
	create_makefile_pl => 'traditional',
	create_license     => 1,
);

$builder->create_build_script();
