package Stilts::Protocol::PSGI;

use strict;
use warnings;

use Moo;
use Carp;
use autodie;
use Try::Tiny;

with 'Stilts::Protocol';

use HTTP::HeaderParser::XS;
use URI::Escape qw//;
use HTTP::Response;
use Plack::Response;
use Plack::Util;
use Sys::Syscall;

sub new_socket
{
  my $self = shift;
  my $sock = shift;

  return $self;
}

my $max_read = 10 * 1024;

sub reader
{
  my $self = shift;
  my $sock = shift;

  my $read_data = $sock->read($max_read);

  if ( !defined $read_data)
  {
    $sock->close;
    return
  }

  my $hdr_end;

  foreach my $hdr_ending ("\r\n\r\n", "\n\n")
  {
    $hdr_end = index $$read_data, $hdr_ending;
    if ($hdr_end > -1)
    {
      $hdr_end += length $hdr_ending;
      last;
    }

    undef $hdr_end;
  }

  if (!defined $hdr_end)
  {
    $sock->push_back_read($read_data);
    return;
  }

  my $headers_str = substr $$read_data, 0, $hdr_end;
  my $headers = HTTP::HeaderParser::XS->new(\$headers_str);
  $sock->push_back_read(substr $$read_data, $hdr_end);

  $sock->reader(sub {
    my $sock = shift;

    my $len = $headers->content_length || 0;
    if ($len > $max_read)
    {
      $sock->close;
      return;
    }

    my $read_data = $sock->read($len);
    if (length $$read_data < $len)
    {
      $sock->push_back_read($read_data);
      return;
    }

    $sock->watch_read(0);

    my $env = $self->create_env($headers, $sock);

    my $res = $self->handler->process($env);

    my ($code, $headers, $body) = @$res;

    my $protocol = $env->{SERVER_PROTOCOL};
    my $code_english = HTTP::HeaderParser::XS->http_code_english($code);

    my $response = "$protocol $code $code_english\r\n";

    my $content_type;
    my $content_length;

    foreach (my $i = 0; $i < scalar @$headers; $i += 2)
    {
      my $k = $headers->[$i];
      my $v = $headers->[$i + 1];

      next
        if $k =~ m/ ( [^\w-] ) /xms;

      next
        if $k !~ m/ ( ^ [[:alpha:]] | [-_] $ ) /xms;

      next
        if $k =~ m/^ Status %/xi;

      if ($k =~ m/^ Content-Length $/xi)
      {
        $len = $v + 0;
      }
      elsif ($k =~ m/^ Content-Type $/xi)
      {
        $content_type = $v;
      }

      $response .= "$k: $v\r\n";

    }

    if (ref $body eq "ARRAY")
    {
      if (!defined $content_length)
      {
        $content_length = 0;
        map { $content_length += length $_ } @$body;
        $response .= "Content-Length: $content_length\r\n";
      }

      $response .= "\r\n";
      $sock->write($response);

      $sock->write(join('', @$body));
    }
    elsif (Plack::Util::is_real_fh($body))
    {
      if (!defined $content_length)
      {
        $content_length = -s $body;
        $response .= "Content-Length: $content_length\r\n";
      }

      $response .= "\r\n";
      $sock->write($response);

      my $otherfd = sub {
        my $len = $body->read(my $data, $max_read);
        if ($len == 0)
        {
          $body->close;
          $sock->reader($self);
          return;
        }
        $sock->write($data);
      };

      warn fileno $body;

      try
      {
        Stilts::Socket->new($body, reader => $otherfd);
      }
      catch
      {
        my $sendfile_return = -1;

        if (Sys::Syscall::sendfile_defined())
        {
          $sendfile_return = Sys::Syscall::sendfile($sock, $body, -1);
        }

        if ($sendfile_return == -1)
        {
          while (!$body->eof)
          {
            $otherfd->();
          }
        }
      };
      return;
    }
    else
    {
      die;
    }

    $sock->reader($self);
  });

  return 1;
}

sub create_env
{
  my $self = shift;
  my $headers = shift;
  my $sock = shift;

  my $t = $Plack::Util::TRUE;
  my $f = $Plack::Util::FALSE;

  my $uri = new URI($headers->getURI);
  my $env = {

        REQUEST_METHOD    => $headers->request_method,
        SCRIPT_NAME       => '',
        PATH_INFO         => $uri->path,
        REQUEST_URI       => $headers->getURI,
        QUERY_STRING      => $uri->query || '',
        SERVER_NAME       => $sock->local_ip_string,
        SERVER_PORT       => $sock->{local_port},
        SERVER_PROTOCOL   => $headers->version,
        CONTENT_LENGTH    => $headers->content_length,
        CONTENT_LENGTH    => $headers->header('Content-Type') || '',
        'psgi.version'      => [ 1, 1 ],
        'psgi.url_scheme'   => 'http', # TODO
        'psgi.input'        => '',
        'psgi.errors'       => *STDERR,
        'psgi.multithread'  => $f,
        'psgi.multiprocess' => $f,
        'psgi.run_once'     => $f,
        'psgi.nonblocking'  => $t,
        'psgi.streaming'    => $t,
  };

    for my $field ( keys $headers->getHeaders) {
        my $key = uc("HTTP_$field");
        $key =~ tr/-/_/;

        $env->{$key} = $headers->header($field)
        if !exists $env->{$key};
    }

  return $env;
}

# We don't actually read anything, we just process the routing
sub _service_reader
{
  my $self = shift;

  my $read_data = $self->sock->read(0);

  $self->service->process($self);

  $self->sock->reader(\&_headers_reader, $self);

  return 1;
}

sub psgi_response
{
  my $self = shift;

  my $res = res_from_psgi([@_]);

  $res->protocol("HTTP/1.0");
  $self->sock->write($res->as_string);
  $self->sock->close;
}

package HTTP::HeaderParser::XS;
sub version
{
  my $self = shift;
  my $vernum = $self->version_number;

  my $major = int($vernum / 1000);
  my $minor = $vernum % 1000;

  return "HTTP/$major.$minor";
}

1;
