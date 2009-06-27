#! /usr/bin/perl

use Test::More tests => 15;

BEGIN {
    use_ok('HTML::Field');
    use_ok('HTML::FieldForm');
}

use HTML::TokeParser;
use CGI;
use strict;

my $form = HTML::FieldForm->new(
        'field_name1' => [ 'Textfield', {
            value     => 'A',
            default   => 'default value 1',
            size      => 10,
            maxlength => 15, } ],
        'field_name2' => [ 'Textfield', {
            value     => 'B',
            default   => 'default value 2',
            size      => 10,
            maxlength => 15, } ],
        'field_name3' => [ 'Textfield', {
            size      => 10,
            maxlength => 15, } ],
);

isa_ok( $form, 'HTML::FieldForm', 
    'HTML::FieldForm object has been created correctly');

$form->{field_name4} = 
    HTML::Field->new('Textfield', name => 'field_name4', size => 10 );

my %values = $form->get_values;
is( $values{field_name2}, 'B',
    "The form can properly deliver the fields' values as a hash" );

$values{field_name4} = 'set_values test';
$form->set_values( \%values );
%values = $form->get_values;
is( $values{field_name4}, 'set_values test',
    "The form can change the fields' values with a hash ref" );

my $q = CGI->new(
    {
        field_name1 => 1,
        field_name2 => 2,
        field_name3 => 'set_values from CGI test'
    }
);
$form->set_values($q);
%values = $form->get_values;
is(
    $values{field_name3}, 'set_values from CGI test',
    "The form can change the fields' values with a CGI object"
);
ok(
    not( defined $values{field_name4} ),
    "The form can change the fields' values with a CGI object, even undef ones"
);

my %html       = $form->creation_html;
my $p          = HTML::TokeParser->new( \$html{field_name2} );
my $parsed_tag = $p->get_tag('input');
ok(
    ref($parsed_tag)            eq 'ARRAY'
      && $parsed_tag->[1]{name} eq 'field_name2'
      && $parsed_tag->[1]{value} == 2,
    "The tag produced by creation_html is indeed an HTML input tag"
);

%html       = $form->editable_html;
$p          = HTML::TokeParser->new( \$html{field_name2} );
$parsed_tag = $p->get_tag('input');
ok(
    ref($parsed_tag)            eq 'ARRAY'
      && $parsed_tag->[1]{name} eq 'field_name2'
      && $parsed_tag->[1]{value} == 2,
    "The tag produced by editable_html is indeed an HTML input tag"
);


$form->reset_values;
%values = $form->get_values;
is( $values{field_name2}, 'default value 2',
    "The form can properly reset the fields' values to their defaults" );

is( (sort $form->names)[2], 'field_name3',
    'The names of the fields are available in a list');
    
%html = $form->set_xhtml(1)->editable_html;
like($html{field_name3}, qr{/>$}, 'It can produce XHTML');

%html = $form->set_xhtml(0)->editable_html;
like($html{field_name3}, qr{[^/]>$}, 'It can produce HTML');
unlike($html{field_name3}, qr{id="field_name3"}, 
    'By default, no id is given');

%html = $form->add_id->editable_html;
like($html{field_name3}, qr{id="field_name3"}, 
    'id is included with add_id');

#$Id: Form.t,v 0.3 2009/06/05 00:35:09 julio Exp julio $
#$Log: Form.t,v $
#Revision 0.3  2009/06/05 00:35:09  julio
#Changed tests to reflect new hash representation of HTML::FieldForm object
#
#Revision 0.2  2007/09/26 04:00:43  julio
#Added one creation_html test
#
#Revision 0.1  2006/12/18 05:47:42  julio
#Added test for new 'names' method
#
#Revision 0.0  2006/12/01 04:02:31  julio
#Initial revision
#
