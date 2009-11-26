#!/usr/bin/perl

use Test::More tests => 10;
use strict;

BEGIN { use_ok 'HTML::Field'; }

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
is($field->value, 'Yellow', 'Field value saved and retrieved correctly');

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
is( $field->value, 'Blue', 'Default and reset_value work correctly');

# $Id: Hidden.t,v 0.3 2009/11/22 05:11:37 julio Exp $
# $Log: Hidden.t,v $
# Revision 0.3  2009/11/22 05:11:37  julio
# Added use_ok for HTML::Field and added / edited some test descriptions
#
# Revision 0.2  2009/05/01 16:25:28  julio
# Fixed Id and Log messages
#

