use v6;

module Perlite::Hash {
    sub hash-has (
        %hash, $what, :$true, :$defined is copy, :$notempty, :$return, :$type
    ) is export(:DEFAULT) {
        if $notempty || $true { $defined = 1; }
        if %hash.exists($what) 
          && ( !$defined  || defined %hash{$what} )
          && ( !$type     || %hash{$what} ~~ $type )
          && ( !$notempty || %hash{$what} ne ''   )
          && ( !$true     || %hash{$what}         )
        {
            if $return { return %hash{$what}; }
            else { return True; }
        }
        else {
            return;
        }
    }
}

