use inc::Module::Install;

name     'Stilts';
author   q{Jon Gentle <atrodo@cpan.org>};
license  'artistic_2';

all_from 'lib/Stilts.pm';

requires 'Moo' => '0.091';
requires 'Danga::Socket' => '1.61';
requires 'JSON' => '2.00';
requires 'HTTP::HeaderParser::XS' => '0.20';

requires 'Try::Tiny' => 0;

build_requires 'Test::More';

auto_install;

WriteAll;

