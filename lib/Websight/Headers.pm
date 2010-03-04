use Websight;
use Perlite::Time;

class Websight::Headers does Websight;

method processPlugin (%opts?) {
    my $config = self.getConfig(:type(Hash));

    if !$config { return; }

    if $config.has('mime', :defined, :type(Array)) {
        for $config<mime> -> $mime {
            my $accept = $.parent.env.has('HTTP_ACCEPT', :return);
            if $accept {
                if $accept ~~ matcher($mime) {
                    $.parent.mimeType($mime);
                    last;
                }
            }
        }
    }
    elsif $config.has('mime', :notempty, :type(Str)) {
        $.parent.mimeType($config<mime>);
    }
    if $config.has('status', :true) {
        $.parent.status($config<status>);
    }
    if $config.has('expires') {
        my $expire = time + $config<expires>;
        my $expiry = formatTime($expire, 'RFC');
        $.parent.addHeader('Expires', $expiry);
    }
    if $config.has('nocache', :true) {
        $.parent.addHeader('Cache-Control', 'no-cache');
    }
    if $config.has('addheaders', :defined, :type(Hash)) {
        $.parent.addHeaders($config<addheaders>);
    }
    if $config.has('delheaders', :defined, :type(Array)) {
        $.parent.delHeaders($config<delheaders>);
    }
      
}

