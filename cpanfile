requires 'perl', '5.012000';

requires 'Danga::Socket', '1.61';
requires 'HTTP::HeaderParser::XS', '0.20';
requires 'HTTP::Response';
requires 'JSON', '2.00';
requires 'Moo', '1.0';
requires 'Plack', '0.20';
requires 'Try::Tiny';
requires 'UNIVERSAL::require', '0.13';

on build => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::More', '0.88';
    requires 'Test::WWW::Mechanize';
};

on develop => sub {
    requires 'Test::Pod', '1.41';
};
