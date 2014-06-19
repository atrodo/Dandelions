#!perl

use Test::More tests => 3;
use autodie;
use FindBin;

use Dandelions;
use Try::Tiny;
use Test::WWW::Mechanize;

my $port = "63021";
my $path = "test_static/";

my $cfg = <<EOD;
[
  {
    "Listen": "127.0.0.1:$port",
    "Protocol": "PSGI",
    "Handler": "Static",
    "Options": {
      "Path": "$path",
    }
  }
]
EOD

my $server = Dandelions->new( config_handle => $cfg );
$server->run_child;

my $mech = Test::WWW::Mechanize->new;

my $file = "1.txt";

open my $file_in, "<", $FindBin::Bin . "/" . $path . $file;
my $content = do { local $/; <$file_in> };

$mech->get_ok("http://127.0.0.1:$port/$file");
$mech->content_is( $content, "File was sent correctly" );

$mech->get("http://127.0.0.1:$port/nothing");
is( $mech->status(), 404, "A proper 404 was returned" );


