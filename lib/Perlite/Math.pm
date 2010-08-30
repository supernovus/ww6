module Perlite::Math;

sub convertBytes ($num, :$from='B', :$to!, :$round, :$floor, :$ceiling) is export(:comp) {
	my ($by,$kb,$mb,$gb,$tb,$pb,$return);
    given $from {
	    when 'B' {
    		$by = $num;
    		$kb = $by / 1024;
    		$mb = $kb / 1024;
    		$gb = $mb / 1024;
            $tb = $gb / 1024;
            $pb = $tb / 1024;
        }
	    when 'KB' {
    		$kb = $num;
    		$mb = $kb / 1024;
    		$gb = $mb / 1024;
            $tb = $gb / 1024;
            $pb = $tb / 1024;
    		$by = $kb * 1024;
        }
        when 'MB' {
    		$mb = $num;
    		$gb = $mb / 1024;
            $tb = $gb / 1024;
            $pb = $tb / 1024;
    		$kb = $mb * 1024;
    		$by = $kb * 1024;
        }
        when 'GB' {
    		$gb = $num;
            $tb = $gb / 1024;
            $pb = $tb / 1024;
    		$mb = $gb * 1024;
    		$kb = $mb * 1024;
    		$by = $kb * 1024;
        }
        when 'TB' {
            $tb = $num;
            $pb = $tb / 1024;
    		$gb = $tb * 1024;
    		$mb = $gb * 1024;
    		$kb = $mb * 1024;
    		$by = $kb * 1024;
        }
        when 'PB' {
            $pb = $num;
            $tb = $pb * 1024;
    		$gb = $tb * 1024;
    		$mb = $gb * 1024;
    		$kb = $mb * 1024;
    		$by = $kb * 1024;
        }
        default {
            $*ERR.say: "Invalid source format in convertBytes, '$from'";
            return $num;
        }
    }
    given $to {
        when 'B'  { $return = $by; }
        when 'KB' { $return = $kb; }
        when 'MB' { $return = $mb; }
        when 'GB' { $return = $gb; }
        when 'TB' { $return = $tb; }
        when 'PB' { $return = $pb; }
        default {
            $*ERR.say: "Invalid output format in convertBytes, '$to'";
            return $num;
        }
    }
    
    if $round {
        $return.=round;
    }
    elsif $floor {
        $return.=floor;
    }
    elsif $ceiling {
        $return.=ceiling;
    }

    return $return;
}

sub numType (Numeric $num) is export(:DEFAULT) { # was :num
    return $num % 2 ?? 'odd' !! 'even';
}

