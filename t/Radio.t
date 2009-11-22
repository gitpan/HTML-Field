#!/usr/bin/perl -w

use Test::More;
use HTML::Field;
use strict;

BEGIN {
    eval 'use Test::Exception; use HTML::TokeParser;';
    plan skip_all => 
        'Test::Exception and HTML::TokeParser needed for testing' 
        if $@
        ; 
}

plan tests => 17;

# Test object creation
my $field;
lives_ok {
    $field = HTML::Field->new(
        'Radio',
        name     => 'RadioTest',
        options  => [qw(Hugo Paco Luis)],
        default  => 'Paco',
    );
} 'Created object and survived';
isa_ok($field, 'HTML::Field::Radio');

is($field->value, 'Paco', 'Default value was applied correctly');
is(ref($field->options), 'ARRAY', 'Options are in an array ref');
is($field->options->[0], 'Hugo', 'Options are indeed in an array ref');
is($field->readonly_tags->{true}, '+', 'Read-only tags are functional');

# Test editable HTML
use Data::Dumper;
$field->xhtml(1);
my %tags = $field->editable_html;
my $tag = join ' ', values %tags;
my $p = HTML::TokeParser->new(\$tag);

my %options = ( Hugo => 1, Paco => 1, Luis => 1);
while (my $token = $p->get_tag('input') ) {
    my $op = $token->[1]{option};
    is($token->[0], 'input', "HTML produced correctly for option $op");
    ok(exists $options{$op}, "$op is indeed a test option");
    ok($token->[1]{checked} eq 'checked', "$op is indeed selected")
        if $op eq 'Paco';
}

lives_ok { $field->value('Luis') } 'Survived changing values';
is($field->value, 'Luis', 'Value was correctly changed');

%tags = $field->editable_html;
$tag = join ' ', values %tags;
$p = HTML::TokeParser->new(\$tag);

while (my $token = $p->get_tag('input') ) {
    my $op = $token->[1]{option};
    next unless $op eq 'Luis';
    is($token->[1]{checked}, 'checked', "$op is indeed selected");
}

# Test read-only HTML
$field->reset_value;
%tags = $field->readonly_html;
is_deeply(
    \%tags, 
    { 
        RadioTest_Hugo => '-', 
        RadioTest_Paco => '+', 
        RadioTest_Luis => '-',
     }, 
    'Read-only HTML is as expected'
);



