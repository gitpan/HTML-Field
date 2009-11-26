#!/usr/bin/perl -w

###########################################################################
# This test reviews the implementation of both Field.pm and Textfield.pm  #
# Other descendants of Field.pm should only test for the methods they     #
# override, like editable_html, value, and readonly_html.                 #
###########################################################################

use Test::More;

use CGI;
use strict;

BEGIN {
    eval "use HTML::TokeParser";
    plan skip_all => "HTML::TokeParser needed to complete tests" if $@;
}

plan tests => 47;

use_ok('HTML::Field');

my $field;

# Try to create an object with a non-existing class
eval {
    $field = HTML::Field->new(
        'Non-existent class',
        name  => 'Yellow',
        value => 'Bright'
    );
};
like( $@, qr/not recognized/,
    'You cannot create fields of an incorrect class' );

# Try to create an un-named field
eval {
    $field = HTML::Field->new(
        'Textfield',
        value     => 'field value',
        default   => 'default value',
        size      => 10,
        maxlength => 15
    );
};
like( $@, qr/^You must name your/, 'You cannot create an unamed field' );

$field = HTML::Field->new(
    'Textfield',
    name      => 'field_name',
    value     => 'field value',
    default   => 'default value',
    size      => 10,
    maxlength => 15
);

isa_ok( $field, 'HTML::Field::Textfield', 'Object has been created' );
is( $field->name,    'field_name',    'Object name is correct' );
is( $field->value,   'field value',   'Object value is correct' );
is( $field->default, 'default value', 'Object default value is correct' );
is( $field->size, 10,
    "Optional attribute is passed correctly from 'new' method" );

$field->maxlength(20);
$field->size(20);
$field->class('css');
$field->disabled(1);

is( $field->size, 20, 'Autoloadable attribute modified correctly' );
is( $field->class, 'css',
    'Autoloadable inherited attribute modified correctly' );
is( $field->disabled, 1,
    'Autoloadable, non-valued attribute modified correctly' );

my $tag        = ( $field->editable_html )[1];
my $p          = HTML::TokeParser->new( \$tag );
my $parsed_tag = $p->get_tag('input');
is( ref($parsed_tag), 'ARRAY',
    'The tag produced by editable_html is indeed an HTML input tag' );

my %attr = %{ $parsed_tag->[1] };
is( $attr{name}, 'field_name', 'Name appears correctly in the HTML input tag' );
is( $attr{value}, 'field value',
    'Value appears correctly in the HTML input tag' );
is( $attr{maxlength}, 20,
    'Autoloadable, valued attribute is OK in HTML input tag' );
is( $attr{class}, 'css',
    'Autoloadable, valued, inherited attr is OK in HTML input tag'
);
is(
    $attr{disabled}, 'disabled',
    'Autoloadable, non-valued, inheritedattr is OK in HTML input tag'
);

$field->reset_value;
is(
    $field->value,
    'default value',
'Method reset_value correctly makes the value equal to its default'
);

$field->value(
    {
        value1     => 'xxx',
        value2     => 'yyy',
        value3     => 'zzz',
        field_name => 'New value'
    }
);
ok( $field->value eq 'New value',
    'The field can get its value from a hash ref of name, value pairs' );

my $q = CGI->new(
    {
        value1     => 'xxx',
        value2     => 'yyy',
        value3     => 'zzz',
        field_name => 'New value from CGI'
    }
);
$field->value($q);
is(
    $field->value,
    'New value from CGI',
    'The field can get its value from a CGI object'
);

$field->value(undef);
ok( not( defined $field->value ), 'The field value can be undefined' );

# Can you change the name of a field?
eval {
    $field->name('new_name');
};
like( $@, qr/^You cannot modify/, 
    'Accessor does not allow modifications of field name' );

# Let's try a non-existent method name:
eval { $field->whatever_non_existing('method'); };
like( $@, qr/^Cannot access method/, 'You cannot call a non-existent method' );

# Test new creation_html method and primary_key, auto attributes
$field = HTML::Field->new(
    'Textfield',
    name      => 'normal_field',
    value     => 'field value',
    default   => 'default value',
    size      => 10
);

$tag        = ( $field->creation_html )[1];
$p          = HTML::TokeParser->new( \$tag );
$parsed_tag = $p->get_tag('input');

is( ref($parsed_tag), 'ARRAY',
    'The tag produced by creation_html is indeed an HTML input tag' );

%attr = %{ $parsed_tag->[1] };
is( $attr{name}, 'normal_field', 
    'Name appears correctly in the HTML input tag' );
is( $attr{value}, 'field value',
    'Value appears correctly in the HTML input tag' );
is( $tag, ( $field->editable_html )[1], 
    'Creation HTML is the same as the editable html tag for a normal field' );

# First case: primary_key called without value -- returns empty, editable field

my $primary_key =  HTML::Field->new(
    'Textfield',
    name        => 'primary_key',
    size        => 10,
    primary_key => 1
);

$tag        = ( $primary_key->creation_html )[1];
$p          = HTML::TokeParser->new( \$tag );
$parsed_tag = $p->get_tag('input');

is( ref($parsed_tag), 'ARRAY',
    'The tag produced by creation_html is indeed an HTML input tag' );

%attr = %{ $parsed_tag->[1] };
is( $attr{name}, 'primary_key', 
    'Name appears correctly in the HTML input tag' );
is( $attr{value}, undef,
    'Value correctly undefined in the HTML input tag' );
is( $tag, ( $primary_key->editable_html )[1], 
    'Creation HTML equals editable HTML tag for an empty primary_key' );

# Second case: let's give the primary key a value. 
# Editable HTML should then return a hidden field and a non-editable tag
$primary_key->value('non-editable');
is( $primary_key->value, 'non-editable', 'Value saved into primary key');

$tag = ( $primary_key->editable_html )[1];
like( $tag, qr/^non-editable/, 'editable_html returns a non-editable label');

$p          = HTML::TokeParser->new( \$tag );
$parsed_tag = $p->get_tag('input');

is( ref($parsed_tag), 'ARRAY',
    'The tag produced by creation_html is indeed an HTML input tag' );

%attr = %{ $parsed_tag->[1] };
is( $attr{name}, 'primary_key', 
    'Name appears correctly in the HTML input tag' );
is( $attr{value}, 'non-editable',
    'Value correctly undefined in the HTML input tag' );
is( $attr{type},  'hidden',
    'The input tag is hidden indeed' );
isnt( $tag, ( $primary_key->creation_html )[1], 
    'Creation HTML is NOT equal to editable html for a valued primary_key' );

# Third case: if it is instead declared as 'auto', then the field will not be
# shown for creation, and it will be hidden for edition.

my $auto_key =  HTML::Field->new(
    'Textfield',
    name        => 'auto_key',
    size        => 10,
    auto        => 1
);

$tag = ( $auto_key->creation_html )[1];
isnt( $tag, ( $auto_key->editable_html )[1], 
    'Creation HTML is NOT equal to editable html tag for an empty auto field' );
like( $tag, qr/^<!--.*-->$/, 
    'Creation HTML is only a comment for empty auto field' ); 

# Fourth case: let's give the auto field a value. Creation HTML  should 
# then return a hidden field and a non-editable tag 
$auto_key->value('non-editable');
is( $auto_key->value, 'non-editable', 'Value saved into auto field');

$tag = ( $auto_key->editable_html )[1];
like( $tag, qr/^non-editable/, 'editable_html returns a non-editable label');

$p          = HTML::TokeParser->new( \$tag );
$parsed_tag = $p->get_tag('input');

is( ref($parsed_tag), 'ARRAY',
    'The tag produced by editable_html is indeed an HTML input tag' );

%attr = %{ $parsed_tag->[1] };
is( $attr{name}, 'auto_key', 
    'Name appears correctly in the HTML input tag' );
is( $attr{value}, 'non-editable',
    'Value correctly undefined in the HTML input tag' );
is( $attr{type},  'hidden',
    'The input tag is hidden indeed' );
isnt( $tag, ( $field->creation_html )[1], 
    'Creation HTML is NOT equal to editable html tag for an empty auto key' );



# print "*********\n", join ' -- ', $field->editable_html, "\n*********\n";

#$Id: Textfield.t,v 0.6 2009/11/26 00:38:51 julio Exp $
#$Log: Textfield.t,v $
#Revision 0.6  2009/11/26 00:38:51  julio
#Corrected removal of HTML::TokeParser from required modules
#
#Revision 0.5  2009/11/22 05:30:23  julio
#Skips all if HTML::TokeParser is missing
#
#Revision 0.4  2009/04/28 04:39:42  julio
#Fixed typo in HTML::Field and an inconsistency introduced in HTML::Field
#regarding creation html.
#
#Revision 0.3  2007/08/12 02:24:04  julio
#Added tests for 'auto', 'primary_key' and creation_html
#
#Revision 0.2  2006/12/14 02:28:58  julio
#Disallowed name changes and changed the test accordingly
#
#Revision 0.1  2006/12/10 01:32:16  julio
#Improved test coverage for parent class
#
#Revision 0.0  2006/12/01 04:01:31  julio
#Initial revision
#
