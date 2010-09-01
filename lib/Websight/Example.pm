use Websight;

class Websight::Example does Websight;

method processPlugin ($config? is copy) {
    if (!$config) { $config = self.getConfig(:type(Hash)); }
    my $name = $.parent.req.get('name') || 'World';
    my $content;
    if $.parent.req.get('text') {
        $.parent.mimeType: 'text/plain';
        $content = "Hello $name, from Webtoo Websight 6.\n\n";
        $content ~= "== The Environment ==\n\n";
        $content ~= $.parent.env.fmt('%s: %s', "\n");
        $content ~= "\n\n== The Parameters ==\n\n";
        $content ~= $.parent.req.params.fmt('%s: %s', "\n");
        if $config {
            $content ~= "\n\n== The Config ==\n\n";
            $content ~= $config.fmt('%s: %s', "\n");
        }
    }
    else {
        $content = "<html><head><title>Hello {$name}</title></head>\n";
        $content ~= "<body><h1>Hello {$name}</h1>\n";
        $content ~= "<p>You have successfully installed Webtoo Websight 6</p>";
        $content ~= "<p>Please read the documentation to configure it.</p>";
        $content ~= "<p>For this example file, you can pass ?name=YourName in the URL to change your name.</p>";
        $content ~= "<h2>The Environment</h2><dl>\n";
        $content ~= $.parent.env.fmt('<dt>%s</dt><dd>%s</dd>', "\n");
        $content ~= "</dl><h2>The Request Parameters</h2><dl>\n";
        $content ~= $.parent.req.params.fmt('<dt>%s</dt><dd>%s</dd>', "\n");
        if $config {
            $content ~= "</dl><h2>The Plugin Config</h2><dl>\n";
            $content ~= $config.fmt('<dt>%s</dt><dd>%s</dd>', "\n");
        }
        $content ~= "</dl><form method=\"POST\"><input type=\"submit\" value=\"Show as text\" name=\"text\" />\n";
        $content ~= "</form></body></html>\n";
   }
    $.parent.content = $content;
}

