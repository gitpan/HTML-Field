#!/usr/bin/perl -w

use Test::More tests => 31;
use HTML::TokeParser;
use HTML::Field;
use strict;

my $field = HTML::Field->new(
    'Select',
    name    => 'select_name',
    options => [qw(azul amarillo  verde)],
    labels  => { azul => 'blue', amarillo => 'yellow', verde => 'green' }
);

my $field2 = HTML::Field->new(
    'Select',
    name    => 'second select',
    options => [qw(a b c d e)]
);

my $field3 = HTML::Field->new(
    'Select',
    name     => 'third select',
    options  => [qw(a b c d e)],
    size     => 3,
    multiple => 1
);

# Object creation
isa_ok( $field,  'HTML::Field::Select', 'Object created properly' );
isa_ok( $field2, 'HTML::Field::Select', 'Object created properly' );

# Test options
$field->options( [ @{ $field->options }, 'naranja' ] );
is( $field->options->[3], 'naranja', 'Options updated correctly' );

# Test labels
is( $field->labels->{azul},
    'blue', 'Labels were passed on correctly and are accessible' );

$field->labels->{naranja} = 'orange';
is( $field->labels->{naranja}, 'orange', 'Labels were updated correctly' );

$field2->labels(
    {
        a => 'abeja',
        b => 'burro',
        c => 'cebra',
        d => 'dragon',
        e => 'elefante'
    }
);
is( $field2->labels->{c}, 'cebra',
    'Labels  were added to an object correctly' );

# Test valued html attributes
$field->size(3);
$field->multiple(1);
is( $field->size, 3, 'Attributes are passed on and read correctly' );

# Test default and value management
$field->default('verde');
ok( not( defined $field->value ), 'Value from creation time is correct' );

$field->reset_value;
is( $field->value, 'verde',
    'Setting default value and reseting the field work fine' );
is( $field->readonly_html, 'green',
    'Read-only html correctly displays the label of the option' );

# Test html production
my $tag = $field->editable_html;
my $p   = HTML::TokeParser->new( \$tag );

my $result = $p->get_tag('select');
is( ref($result), 'ARRAY', 'Editable HTML is a select tag' );
is( $result->[1]->{size},
    3, 'Valued attributes are correctly put into the HTML tag' );
ok( exists $result->[1]->{multiple},
    'Non-valued attributes appear correctly in the HTML tag' );

like(
    $tag,
    qr/<option value="verde" selected>/,
    'Default option is being selected'
);

# Test html production of field w/o labels
$tag = $field3->editable_html;
$p   = HTML::TokeParser->new( \$tag );

$result = $p->get_tag('select');
is( ref($result), 'ARRAY', 'Editable HTML is a select tag' );
is( $result->[1]->{size},
    3, 'Valued attributes are correctly put into the HTML tag' );
ok( exists $result->[1]->{multiple},
    'Non-valued attributes appear correctly in the HTML tag' );

$result = $p->get_tag('option');
is( ref($result), 'ARRAY', 'First option found for field w/o labels' );
is( $result->[1]->{value}, 'a', 'Value of first option is correct' );
like( $tag, qr|>a</option>|,
    'Option appears as value and label for options w/o label' );
    
# Test editable html production with incomplete labels
$field3->options( [ @{ $field3->options }, 'negro' ] );
$tag = $field3->editable_html;
like( $tag, qr|<option value="negro">negro</option>|,
    'Editable html works with incomplete labels' );

# Test production of read only html
$tag = $field3->readonly_html;
is( $tag, '-----', 'Read-only html works w/o value' );

$field3->value('c');
is( $field3->value, 'c', 'Value passed on correctly' );

$tag = $field3->readonly_html;
is( $tag, 'c', 'Read-only html works with value' );

# Test editable html production with incomplete/missing labels
$field3->value('negro');
$tag = $field3->readonly_html;
is( $tag, 'negro',
    'Read-only html works with incomplete/missing labels' );

# Test creation of incorrect field
my $field1;

eval { $field1 = HTML::Field->new( 'Select', name => 'incorrect' ); };
like(
    $@,
    qr/does not contain options/,
    'You cannot create a select field without options'
);

eval {
    $field1 = HTML::Field->new(
        'Select',
        name    => 'incorrect',
        options => 'an option'
    );
};
like(
    $@,
    qr/does not contain options/,
    'You cannot create a select field without options as array ref'
);

eval {
    $field1 = HTML::Field->new(
        'Select',
        name    => 'incorrect',
        options => [ 'a', 'b', 'c' ],
        labels  => 'labels should be a hash ref'
    );
};
like(
    $@,
    qr/labels should be a hash ref/,
    'You cannot create a select field with labels not in a hash ref'
);

# Test creation of html with invalid options/labels
eval {
    $field->options(undef);
    $tag = $field->editable_html;
};
like( $@, qr/object does not contain options/,
    'You cannot create editable html from a field without options' );

eval {
    $field->options('incorrect');
    $tag = $field->editable_html;
};
like( $@, qr/object does not contain options/,
    'You cannot create editable html from a field with invalid options' );

eval {
    $field->options( [ qw(a b c ) ] );
    $field->labels('Invalid labels');
    $tag = $field->editable_html;
};
like( $@, qr/labels should be a hash ref/,
    'You cannot create editable html with invalid labels' );


