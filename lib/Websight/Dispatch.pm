use Websight;

class Websight::Dispatch does Websight;

method processPlugin (%opts?) {
    say "debug: we made it this far!" if $.parent.debug;
    $.parent.content = "Hello World";
    #$.parent.content = %.parent.metadata // "Hello World";
}

