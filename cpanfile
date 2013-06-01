requires 'perl', '5.008005';

requires 'autodie';
requires 'Moo' => '1.0';
requires 'Danga::Socket' => '1.61';
requires 'JSON' => '2.00';
requires 'HTTP::HeaderParser::XS' => '0.20';
requires 'Plack' => '0.20';
requires 'HTTP::Response';

requires 'UNIVERSAL::require' => 0.13;

requires 'Try::Tiny' => 0;

on test => sub {
    requires 'Test::More', '0.88';
};
