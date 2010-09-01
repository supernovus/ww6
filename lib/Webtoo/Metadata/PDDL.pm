role Webtoo::Metadata::PDDL;

use Perlite::Data;
use Perlite::File;

has $.datadir = '.';
has $.dataext = '.wtdl';

has $.metadata is rw = Perlite::Data.make(
  :data({
    :plugins( [ 'Example' ] ),
    :root( [ '' ] ),
    'request' => {
       :host($.host),
       :proto($.proto),
       :path($.path),
       :type($.req.type),
       :method($.req.method),
       :query($.req.query),
       :params($.req.params),
       :userip($.req.remoteAddr),
       :browser($.req.userAgent),
       :uri($.uri),
       :url($.proto ~ '://' ~ $.host);
       :urlhttp('http://' ~ $.host);
       :urlhttps('https://' ~ $.host);
    },
  }),
  :find(sub ($me, $file) {
    findFile($file, $.datadir, :subdirs($.metadata<root>), :ext($.dataext));
  }),
);

