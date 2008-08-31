
use strict;
use warnings;
use Test::More;

eval { require Test::Spelling; Test::Spelling->import() };

plan skip_all => "Test::Spelling required for testing POD coverage" if $@;

add_stopwords(qw/
	html
	HTML
	QLD
	Param
	API
	ISA
	Arg
	DocPerl
	docperl
	pl
	pm
	ppm
	IIS
	tmpl
	CPAN
	LightHTTPD
	conf
	checksetup
	Readonly
	firefox
	cgi
	http
	DocPerl's
	clearcache
	eg
	hightlighted
	initialisation
	initialises
	inc
	ini
	IncFilders
	IncFolders
	LocalFolders
	url
	api
	GraphViz
/);
all_pod_files_spelling_ok();
