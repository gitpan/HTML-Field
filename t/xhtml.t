#! /usr/bin/perl-w

use Test::More tests => 27;

use warnings;
use strict;

#############################################
# Test XHTML option for HTML::Field objects #
#############################################

BEGIN { use_ok(  'HTML::Field' ); }

# Enter XHTML mode
is( HTML::Field->xhtml() , 0, 'XHTML is not the default'  );
is( HTML::Field->xhtml(1), 1, 'XHTML output has been set' );
is( HTML::Field->xhtml() , 1, 'XHTML mode is really on'   ); 

# Define one field of every class
my @fields = ( HTML::Field->new('Textfield', 
                    name => 'name',
                    size => 25),
               HTML::Field->new('Hidden', 
                    name => 'sid', 
                    value => 'random'),
               HTML::Field->new('Textarea',  
                    name => 'address',   
                    cols => 20, 
                    rows => 4),
               HTML::Field->new('Password',
                    name => 'passwd',
                    size => 15),
               HTML::Field->new('Select',
                    name      => 'select_color',
                    options   => [qw(red yellow brown)],
                    default   => 'red',
                    labels    => {red    => 'Color of apples',
                                  yellow => 'Color of mangos!',
                                  brown  => 'Color of chocolate'},
                    multiple  => 1,      # Multiple is either true or false                         
                    size      => 1 ),    # Size of select box
              HTML::Field->new('Radio',
                    name      => 'Flavors',
                    options   => [qw(Sandia Limon Uva)],
                    default   => 'Uva' ),
              HTML::Field->new('Checkbox',
                    name      => 'Additional',
                    option    => 'Strawberry',
                    default   => 1,
                    read_only_tags => { true => 'X', false => 'o'} )
);

my $field;

# Test object creation              
foreach $field ( @fields ) {
    isa_ok( $field, 'HTML::Field' );
}

# Test all simple tags (textfield, password, hidden, radio, checkbox)
foreach $field ( @fields[0, 1, 3, 5, 6,] ) {
    like( ( $field->creation_html )[1], qr|^<[^<]+/>$|s, 
        'Creation (X)HTML for ' . ref $field );
    
    like( ( $field->editable_html )[1], qr|^<[^<]+/>$|s, 
        'Editable (X)HTML for ' . ref $field );
    
    # Check special cases
    if ( ref $field eq 'HTML::Field::Hidden' ) {
        is( ( $field->readonly_html )[1], '<!-- Hidden field -->', 
            'Read only (X)HTML for HTML::Field::Hidden is a comment' );
    } elsif ( ref $field eq 'HTML::Field::Checkbox' ) {
        like( ( $field->creation_html )[1], qr|^<.*checked="checked".*/>$|s,
            'Non-valued attribute handled correctly for HTML::Field::Checkbox');
    }
}

# Finally test all fields that produce closing tags (textarea, select)
foreach $field ( @fields[2, 4] ) {
    like( ( $field->creation_html )[1], qr|^<.*?>.*</[^<]+>$|s, 
        'Creation (X)HTML for ' . ref $field );
    
    like( ( $field->editable_html )[1], qr|^<.*?>.*</[^<]+>$|s, 
        'Editable (X)HTML for ' . ref $field );
}

 
