#!/usr/bin/perl -w

use Test::More tests => 13;
use HTML::Field;
use strict;

my $field = HTML::Field->new(
    'Textarea',
    name    => 'textarea'
);

isa_ok( $field, 'HTML::Field::Textarea', 'Object created properly' );

# Autoloadable accessors/mutators
eval {
    $field->cols(40);
};
is($@, '', 'Textarea field columns number declared OK');
is($field->cols, 40, 'Textarea field columns number retrieved OK');

eval {
    $field->rows(6);
};
is($@, '', 'Textarea field rows number declared OK');
is($field->cols, 40, 'Textarea field rows number retrieved OK');

# Editable HTML
my $tag = ( $field->editable_html )[1];
like ( $tag, qr/^<textarea.*>$/i,
    'Editable HTML is producing the right input type' );
like ( $tag, qr/name="textarea"/,
    'Editable HTML is writing the name of the field correctly' );
like ( $tag, qr/cols="40"/,
    'Editable HTML contains the correct columns number');
like ( $tag, qr/rows="6"/,
    'Editable HTML contains the correct rows number');
like ( $tag, qr|<textarea.*?></textarea>$|i,
    'Editable HTML works OK without a value' );
    
$field->value('blue');
is($field->value, 'blue', 'value method is working OK');
$tag = ( $field->editable_html )[1];
like ( $tag, qr|<textarea.*?>blue</textarea>$|i,
    'Editable HTML works OK without a value' );

my $read_only = $field->readonly_html;
is( $read_only, 'blue',
    'Read only HTML returns the value of the field only' );

# $Id: Textarea.t,v 0.1 2009/06/27 22:47:24 julio Exp $
# $Log: Textarea.t,v $
# Revision 0.1  2009/06/27 22:47:24  julio
# Removed 'wrap' attribute from tests
#

