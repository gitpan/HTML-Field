use Test::More tests => 9;
use HTML::Field;
use strict;

my $field = HTML::Field->new(
    'Hidden',
    name    => 'Hidden',
    default => undef
);

isa_ok( $field, 'HTML::Field::Hidden', 'Object created properly' );

eval {
    $field->editable_html;
};
like ($@, qr/^All hidden fields must have a value/,
    'Error thrown correctly for hidden fields without value');

$field->value('Yellow');
is($field->value, 'Yellow');

my $tag = ( $field->editable_html )[1];
like ( $tag, qr/^<input type="hidden".*>$/i,
    'Editable HTML is producing the right input type' );
like ( $tag, qr/name="Hidden"/,
    'Editable HTML is writing the name of the field correctly' );
like ( $tag, qr/value="Yellow"/,
    'Editable HTML contains the correct value of the field' );

my $read_only = $field->readonly_html;
is( $read_only, '<!-- Hidden field -->',
    'Read only HTML returns the hidden form element' );

# Default value is 'undef'...
$field->reset_value;
eval {
    $tag = ( $field->editable_html )[1];
};
like ($@, qr/^All hidden fields must have a value/,
    'Error thrown correctly for hidden fields without value');
    
$field->default('Blue');
$field->reset_value;
is( $field->value, 'Blue', 'default and reset_value work correctly');

# $Id$
# $Log$

