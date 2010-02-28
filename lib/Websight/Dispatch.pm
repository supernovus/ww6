use Websight;

class Websight::Dispatch does Websight;

method processPlugin (%opts?) {
    my $name = $.parent.req.get('name') || 'World';
    my $content;
    if $.parent.req.get('text') {
        $.parent.mimeType: 'text/plain';
        $content = "Hello $name\n\n";
        $content ~= "== The Environment ==\n\n";
        $content ~= $.parent.env.fmt("%s: %s", "\n");
    }
    else {
        $content = "<html><head><title>Hello $name</title></head>\n";
        $content ~= "<body><h1>Hello $name</h1><h2>The Environment</h2><dl>\n";
        $content ~= $.parent.env.fmt("<dt>%s</dt><dd>%s</dd>", "\n");
        $content ~= "</dl><form method=\"POST\"><input type=\"submit\" />\n";
        $content ~= "</form></body></html>\n";
    }
    $.parent.content =  $content;
}

