use Websight;

class Websight::Headers does Websight;

use Hash::Has;
use DateTime::Utils;
use DateTime::Math;

method processPlugin ($default_config?) {
    my $config = self.getConfig(:type(Hash)) // $default_config;

    if !$config { return; }

    if hash-has($config, 'mime', :defined, :type(Array)) {
        for $config<mime> -> $mime {
            my $accept = hash-has($.parent.env, 'HTTP_ACCEPT', :return);
            if $accept {
                if $accept ~~ matcher($mime) {
                    $.parent.mimeType($mime);
                    last;
                }
            }
        }
    }
    elsif hash-has($config, 'mime', :notempty, :type(Str)) {
        $.parent.mimeType($config<mime>);
    }
    if hash-has($config, 'status', :true) {
        $.parent.status($config<status>);
    }
    if hash-has($config, 'expires') {
        my $expires = $config<expires>;
        my $unit = 's';
        if ($expires ~~ /^(\d+ [\.\d+]?)(<[smhdwMy]>)$/) {
          $unit = ~$1;
          $expires = +$0;
        }
        my $expire = DateTime.now + to-seconds($expires, $unit);
        my $expiry = rfc2822($expire);
        $.parent.addHeader('Expires', $expiry);
    }
    if hash-has($config, 'nocache', :true) {
        $.parent.addHeader('Cache-Control', 'no-cache');
    }
    if hash-has($config, 'addheaders', :defined, :type(Hash)) {
        $.parent.addHeaders($config<addheaders>);
    }
    if hash-has($config, 'delheaders', :defined, :type(Array)) {
        $.parent.delHeaders($config<delheaders>);
    }

}

