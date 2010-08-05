use Websight;

class Websight::Headers does Websight;

use Perlite::Time;

method processPlugin (%opts?) {
    my $config = self.getConfig(:type(Hash));

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
        my $expire = time + $config<expires>;
        my $expiry = formatTime($expire, 'RFC');
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

