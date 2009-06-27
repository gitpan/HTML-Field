use Test::More tests => 13;
use HTML::Field;
use strict;

my $field = HTML::Field->new(
    'Password',
    name    => 'passwd'
);

isa_ok( $field, 'HTML::Field::Password', 'Object created properly' );

# Autoloadable accessors/mutators
eval {
    $field->size(10);
};
is($@, '', 'Password field size declared OK');
is($field->size, 10, 'Password field size retrieved OK');

eval {
    $field->maxlength(15);
};
is($@, '', 'Password field maximum length declared OK');
is($field->maxlength, 15, 'Password field maximum length retrieved OK');


# Editable HTML
my $tag = ( $field->editable_html )[1];
like ( $tag, qr/^<input type="password".*>$/i,
    'Editable HTML is producing the right input type' );
like ( $tag, qr/name="passwd"/,
    'Editable HTML is writing the name of the field correctly' );
unlike ( $tag, qr/value=/,
    'Editable HTML works OK without a value' );
    
$field->value('blue');
is($field->value, 'blue', 'value method is working OK');
$tag = ( $field->editable_html )[1];
like ( $tag, qr/^<input type="password".*>$/i,
    'Editable HTML is producing the right input type' );
like ( $tag, qr/name="passwd"/,
    'Editable HTML is writing the name of the field correctly' );
like ( $tag, qr/value="blue"/,
    'Editable HTML handles the value correctly' );

my $read_only = $field->readonly_html;
like( $read_only, qr/^\*+$/,
    'Read only HTML returns an asterisk mask only' );

# $Id
# $Log

