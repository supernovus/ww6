## This was Perlite::Class::Basic
## Now rebranded SimpleClass for inclusion with ww6for5.
## Also enhanced to be more strict, and to allow for easy init() statements.

package SimpleClass;

use strict;
use warnings;

use Carp;

=item new()

A default new class. Creates a new object and runs init() on it. 

You shouldn't have to override new(). Use init() for that purpose instead.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->init(@_);
    return $self;
}

=item init()

The function which you should override in order to add custom
fields and initialization data to your class.

The init() function is called by the new() function, which should
not be overridden.

This should call either $self->_init_simple(@_) for simple initialization,
or $self->_init_class(\%memberDef, @_) for more strict initialization.

=cut

sub init {
	my $self = shift;
	$self->_init_simple(@_);
}

=item getParams()

Find out the parameters and return them, using the following rules.

C<< $params = $self->getParams(\@arrayref); >>

If the first parameter is an array reference, it will assume it to
be a set of pairs, and create a hash reference based on it.

C<< $params = $self->getParams(\%hashref); >>

If the first parameter is a hash reference, it will return it.

C<< $params = $self->getParams(@_); >>

If none of the above rules match, assume that the content of
the params is a pair, either in hash or array syntax, and build
a hash array based on it.

E.g.

  $params = $self->getParams(key1=>'value1', key2=>'value2');

The most common usage of this function is to parse the input from
a function call. It's used internally by the _init() function.

=cut

sub getParams {
	my $self = shift;
	my %params;
	if (ref($_[0]) eq "HASH") {
		%params = %{$_[0]};
	} elsif (ref($_[0]) eq "ARRAY") {
		%params = @{$_[0]};
	} else {
		%params = @_;
	}
	return \%params;
}

=item _init_simple()

In your init() function somewhere:

C<< $self->_init_simple(@_); >>

Turns any hash elements into class members. There is no strict checking,
and no automatic addition of accessors (which means you need to do that
part yourself using has_ro() and has_rw() to create accessors.)

=cut

sub _init_simple {
	my $self = shift;
	my %params = %{$self->getParams(@_)};
	foreach my $key (keys %params) {
		$self->{$key} = $params{$key};
	}
}

=item _init_class()

NOTE: This replaces the call to _init_simple(). You cannot use them together.

In your init() function somewhere:

C<< $self->_init_class($rules, @_);

The rules is a hash reference that defines the valid class attributes.
The key of the hash is the name of the attribute, the value is another hash
with any options for the attribute.

Options:

  ro => 1        Create a readonly accessor, same name as the attribute.
  rw => 1        Create a readwrite accessor, same name as the attribute.
  ro => $name    Create a readonly accessor, with defined name.
  rw => $name    Create a readwrite accessor, with defined name.

  default => $value   Specify a default value for the attribute.

  required => 1   This parameter is required.

=cut

sub _init_class {
    my $self  shift;
    my $rules = shift;
    if (ref $rules ne 'HASH') { 
        croak "_init_class requires a rule definition"; 
    }

    my %params = %{$self->getParams(@_)};

    foreach my $rule (keys %{$rules}) {
        if ($rules->{$rule}->{required}) {
            if (!exists(%params{$rule})) {
                croak "Missing required parameter '$rule'.";
            }
        }
        if ($rukes->{$rule}->{rw}) {
            if ($rules->{$rule}->{rw} ne '1') {
                $self->has_rw({ $rule => $rules->{$rule}->{rw} });
            }
            else {
                $self->has_rw($rule);
            }
        }

        if ($rules->{$rule->}{ro}) {
            if ($rules->{$rule}->{ro} ne '1') {
                $self->has_ro({ $rule => $rules->{$rule}->{rw} });
            }
            else {
                $self->has_ro($rule);
            }
        }

        if ($rules->{$rule}->{default}) {
            $self->{$key} = $rules->{$rule}->{default};
        }
    }

 	foreach my $key (keys %params) {
        if (exists($rules{$key})) {
		    $self->{$key} = $params{$key};
        }
        else {
            carp "invalid class member: '$key', skipped.";
        }
	}

}

### Eerie magical code of DOOM!

sub _check_redefine {
    my $class  = shift;
    my $method = shift;

    if ($class->can($method)) {
        carp "attempt to redefine method '$method'"; 
        return 1;
    }
    else {
        return 0;
    }
}

sub has_rw {
    my $class = shift;
    $class->_add_class_attrib('_has_rw', @_);
}

sub has_ro {
    my $class = shift;
    $class->_add_class_attrib('_has_ro', @_);
}

sub _add_class_attrib {
    my $class  = shift;
    my $method = shift;
    for my $attribute (@_) {
        next if $class->_check_redefine($attribute);
        if (ref $attribute eq 'HASH') {
            for my $external (keys %{$attribute}) {
                $class->$method(
                    $external, 
                    $attribute->{$external},
                );
            }
        }
        else {
            $class->$method($attribute, $attribute);
        }
    }
}

sub _has_rw {
    my $class     = shift;
    my $attribute = shift;
    my $method    = shift;
    
    return if $class->_check_redefine($method);

    no strict 'refs';

    *{$method} = sub {
        my $self = shift;
        if (@_) {
            if (@_ > 1) {
                $self->{$attribute} = [@_];
            }
            else {
                $self->{$attribute} = shift;
            }
            return $self;
        }
        else {
            return $self->{$attribute};
        }
    };
}

sub _has_ro {
    my $class     = shift;
    my $attribute = shift;
    my $method    = shift;
    
    return if $class->_check_redefine($method);

    no strict 'refs';

    *{$method} = sub {
        my $self = shift;
        if (@_) { carp "attempt to set readonly attribute '$attribute'"; }
        return $self->{$attribute};
    };
}


## Don't use this unless you know what you are doing!
sub add_method {
    my $class  = shift;
    my $name   = shift;
    my $code   = shift;

    no strict 'refs';

    return if $class->_check_redefine($name);
    *{$name} = $code;
    return $class;
}

## This is simpler than add_method() and is preferred if possible.
sub delegate_methods {
    my $class     = shift;
    my $delegate  = shift;

    for my $method (@_) {
        if (ref $method eq 'HASH') {
            for my $external (keys %{$method}) {
                $class->_delegate_method(
                    $delegate, 
                    $external, 
                    $method->{$external},
                );
            }
        }
        else {
            $class->_delegate_method( $delegate, $method, $method );
        }
    }
}

sub _delegate_method {
    my $class     = shift;
    my $delegate  = shift;
    my $external  = shift;
    my $local     = shift;

    return if $class->_check_redefine($local);
    no strict 'refs';
    *{$local} = sub {
        $class->{$delegate}->$external(@_);
    }
}

1;

