use inc::Module::Install;

name     'Stilts';
all_from 'lib/Stilts.pm';
author   q{Jon Gentle <atrodo@cpan.org>};
license  'artistic_2';

build_requires 'Test::More';

auto_install;

WriteAll;

