# Test suite for HTML::Field::Checkbox Class

use Test::More;
use HTML::Field;
use strict;

BEGIN {
    eval 'use Test::Exception';
    plan skip_all => 'Test::Exception needed for testing' if $@;
}

plan tests => 31;

my $checkbox = HTML::Field->new(
    'Checkbox',
    name    => 'NewCheckbox',
    default => 1
);

isa_ok( $checkbox, 'HTML::Field::Checkbox', 'Object created properly' );

is( $checkbox->value, 1, 'Value is boolean (true)' );
ok( $checkbox->checked,
    "Value is correctly switching the 'checked' attribute" );

$checkbox->value('off');
ok( not( defined $checkbox->value ), 'Value is boolean (false)' );
ok( not( $checkbox->checked ),
    "Value is correctly switching the 'checked' attribute" );

$checkbox->value('ON');
my $tag = ( $checkbox->editable_html )[1];
like(
    $tag,
    qr/^<input type="checkbox".*>$/,
    'Editable HTML is producing the right input type and starting angle'
);
like(
    $tag,
    qr/name="NewCheckbox"/,
    'Editable HTML is writing the name of the field correctly'
);
like( $tag, qr/ checked/,
    "Editable HTML contains the non-value 'checked' argument" );

my $read_only = $checkbox->readonly_html;
is( $read_only, '+',
    'Read only HTML is accessing the default read only tags (true)' );

$checkbox->value('OFF');
$read_only = ( $checkbox->readonly_html )[1];
is( $read_only, '-',
    'Read only HTML is accessing the default read only tags (false)' );

$checkbox->readonly_tags( true => 'X', false => 'O' );
$checkbox->value(1);
$read_only = ( $checkbox->readonly_html )[1];
is( $read_only, 'X',
    'Read only HTML is accessing user-defined read only tags (true)' );

$checkbox->value(0);
$read_only = ( $checkbox->readonly_html )[1];
is( $read_only, 'O',
    'Read only HTML is accessing user-defined read only tags (false)' );

# Test the creation of a checkbox with read only tags
$checkbox = HTML::Field->new(
    'Checkbox',
    name          => 'OtherCheckbox',
    readonly_tags => { true => '*', false => '---' }
);
isa_ok( $checkbox, 'HTML::Field::Checkbox',
    'Object created with read only tags' );

$read_only = ( $checkbox->readonly_html )[1];
is( $read_only, '---',
    'Read only HTML is accessing user-defined read only tags (false)' );

$checkbox->value('t');
$read_only = ( $checkbox->readonly_html )[1];
is( $read_only, '*',
    'Read only HTML is accessing user-defined read only tags (true)' );

# Test for errors with readonly_tags:
eval { $checkbox->readonly_tags( incorrect => 1, false => 'ooo' ); };
like(
    $@,
    qr/^readonly_tags must be called with/,
    'Incorrect arguments to readonly_tags are rejected (true)'
);

eval { $checkbox->readonly_tags( incorrect => 1, true => 'ooo' ); };
like(
    $@,
    qr/^readonly_tags must be called with/,
    'Incorrect arguments to readonly_tags are rejected (false)'
);

# Test the different valid values for the checkbox:
foreach ( 1, 'on', 'ON', 'On', 't', 'T' ) {
    $checkbox->value($_);
    is( $checkbox->value, 1, "Value $_ maps correctly to 1" );
}

foreach ( undef, 0, 'off', 'OFF', 'Off', 'f', 'F' ) {
    $checkbox->value($_);
    ok( not( defined $checkbox->value), 'String maped correctly to undef' );
}

dies_ok { $checkbox->value('Whatever'); }
    'Exception raised when unknown values are entered as valuess';
    

