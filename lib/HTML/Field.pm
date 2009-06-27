package HTML::Field;

use Carp;
use strict;

our $AUTOLOAD;
our $VERSION = '1.18';
our $XHTML   = 0;

# The following hash contains HTML attributes common to all form elements.
# By modifying the values of the hash you would actually change the default
# value since it is fed directly into the object during its creation.
my %autoloadable = (
    accesskey => undef,
    id        => undef,
    title     => undef,
    class     => undef,
    style     => undef,
    lang      => undef,
    dir       => undef,
    disabled  => undef,
    readonly  => undef,
    tabindex  => undef
);

# These are the available field types
my %packages = (
    Textfield   => 'HTML::Field::Textfield',
    Textarea    => 'HTML::Field::Textarea',
    Checkbox    => 'HTML::Field::Checkbox',
    Hidden      => 'HTML::Field::Hidden',
    Password    => 'HTML::Field::Password',
    Radiobutton => 'HTML::Field::Radiobutton',
    Radio       => 'HTML::Field::Radio',
    Select      => 'HTML::Field::Select',
);

# The following class method switches from HTML to XHTML 
sub xhtml {
    my $class = shift;
    my $xhtml = shift;

    if ( defined $xhtml ) {
        $XHTML = $xhtml;
    }
    return $XHTML;
}

# This is the constructor for the class and its descendants. 
# Each descendant class is responsible of adding attributes  
# to the different lists (_autoloadable, etc).               

sub new {
    my $super = shift;
    my $type  = shift;

    # Check if the required type exists
    my $class = $packages{$type};
    croak "Type $type was not recognized\n" unless defined $class;

    # Create object of the requested type
    my $self = {
        name        => undef,
        default     => undef,
        value       => undef,
        primary_key => undef,
        auto        => undef,

        # List of  valued html tag attributes used
        # to generate the tags (like size="10")
        _valued_html_attr =>
          [qw(accesskey id title class style lang dir tabindex)],

        # List of non-valued html tag attributes used to generate
        # the tags (like 'checked' in a radio button)
        _nonvalued_html_attr => [qw(disabled readonly)],

        # Hash of object attributes whose accessors/mutators 
        # will be through AUTOLOAD
        _autoloadable => {%autoloadable},

        # Defaults for the autoloadable, Field class attributes
        %autoloadable,

        # And finally consider what the user wants!
        @_
    };
    bless $self, $class;

    croak "You must name your $class!"
      unless defined $self->name;    # Name is a mandatory argument

    $self->reset_value
      unless defined $self->value;   # Enforce default, if given

    # Now perform any subclass-specific initialization
    $self->initialize;

    return $self;
}

sub name {
    my $self = shift;

    croak 'You cannot modify the name of a ' . ref $self if @_;
    return $self->{name};
}

sub default {
    my $self = shift;
    $self->{default} = shift if (@_);
    return $self->{default};
}

# Shall receive a scalar value, a hash of values from which it has to pick
# its value (one to one) or else a CGI object (many values to one field).
# In case there are several form elements to pick from the given object, 
# then this method would be overriden by a subclass, which would then
# compute a scalar value.
# It returns the value of the field (after modification, if any).
sub value {
    my $self = shift;
    if (@_) {
        my $value = shift;
      SWITCH: {
            ref($value) eq 'CGI'
              && do {
                $self->{value} = $value->param( $self->name );
                last SWITCH;
              };
            ref($value)
              && do {
                $self->{value} = $value->{ $self->name };
                last SWITCH;
              };
            $self->{value} = $value;
        }
    }
    return $self->{value};
}

# This one sets the value of a field equal to the default
sub reset_value {
    my $self = shift;
    $self->value( $self->default );
    return;
}

# This method will display the read-only value of the field. It must
# be overriden by those fields whose read only html is different from their
# simple value or by those of multiple fields.
# It returns a list of name, value pairs that can be used to build a hash
# suitable for HTML::Template.
sub readonly_html {
    my $self = shift;
    return ( $self->name, $self->value );
}

# This method should return the HTML form element that will be used to
# display the editable fields.
# It MUST be overriden.
# It must return a list of name, value pairs that can be used to build a
# hash suitable for HTML::Template.
sub editable_html {
    my $self = shift;
    carp "The html method in class " 
        . ref($self) . " has not been implemented"
        ;
}

# create_html will return the editable HTML form element that will be used
# for record creation. It will allow for primary key edition (except
# for fields marked as auto.)
sub creation_html {
    my $self = shift;
    return $self->editable_html;
}

# This method will help for the generation of HTML tags by generating the
# attributes list of every tag.
sub _editable_html {
    my $self = shift;
    my $tag  = '';
    foreach ( @{ $self->{_valued_html_attr} } ) {
        $tag .= " $_=\"" . $self->$_ . '"' if defined $self->$_;
    }
    foreach ( @{ $self->{_nonvalued_html_attr} } ) {
        if ( $self->$_ ) {
            $tag .= " $_";
            $tag .= qq{="$_"} if $self->xhtml;
        }
    }
    return $tag;
}

#   Autoload routine to create simple accessor/mutators      #
#   for descendants of this class. Note that descendants     #
#   must have a '_autoloadable' field containing a hash      #
#   reference with the list of fields that can be accessed   #
#   using this routine.                                      #
sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) || croak 'Called a non-existent class method';
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    return unless $name =~ /[^A-Z]/;
    croak "Cannot access method '$name' in class $type"
      unless ( exists $self->{_autoloadable}->{$name} );
    if (@_) {
        return $self->{$name} = shift;
    }
    else {
        return $self->{$name};
    }
}

#####################################################################
#####################################################################
##################### Subclasses begin here #########################
#####################################################################
#####################################################################

package HTML::Field::Checkbox;

use Carp;
use strict;
use vars qw(@ISA);

@ISA = ('HTML::Field');

# read_only_tags are the representations of the checkbox in a non-editable
# scenario. You can pass any text you want to represent a 'true' state
# or a 'false' state, like images or other characters.
sub initialize {
    my $self = shift;
    $self->{readonly_tags} = { true => '+', false => '-' }
      unless defined $self->{readonly_tags};
    push @{ $self->{_nonvalued_html_attr} }, 'checked';
    return $self;
}

# Value is only boolean.
my %true  = map { $_ => 1 } ( 1, 'on',  'ON',  'On',  't', 'T' );
my %false = map { $_ => 1 } ( 0, 'off', 'OFF', 'Off', 'f', 'F' );

sub value {
    my $self = shift;
    if (@_) {
        $self->SUPER::value(@_);

        if ( defined $self->{value} && exists $true{ $self->{value} } ) {
            $self->{value} = 1;
        }
        elsif ( not( defined $self->{value} )
            || exists $false{ $self->{value} } )
        {
            $self->{value} = undef;
        }
        else {
            croak "Unrecognized value for checkbox: $self->{value}\n";
        }
    }
    return $self->{value};
}

sub checked {
    my $self = shift;
    return $self->value;
}

sub editable_html {
    my $self = shift;
    my $field =
        '<input type="checkbox" name="'
      . $self->name . '"'
      . ' value="on"'
      ;
    if ($self->checked) {
        $field .= 'checked';
        $field .= '="checked"' if $self->xhtml;
    }
    $field .= $self->_editable_html;
    $field .= HTML::Field->xhtml ? '/>' : '>';
    return ( $self->name, $field );
}

sub readonly_tags {
    my $self = shift;
    if (@_) {
        my %args = @_;
        croak 
            "readonly_tags must be called with the following arguments:\n"
            . "true => 'representation t', false => 'representation f'"
            unless ( exists $args{true} && exists $args{false} )
            ;
            
        $self->{readonly_tags} = \%args;
        return;
    }
    if ( $self->value ) {
        return $self->{readonly_tags}->{'true'};
    }
    else {
        return $self->{readonly_tags}->{'false'};
    }
}

sub readonly_html {
    my $self = shift;
    return ( $self->name, $self->readonly_tags );
}

#####################################################################
#####################################################################
#####################################################################

package HTML::Field::Hidden;

use Carp;
use strict;
use vars qw(@ISA);

@ISA = ('HTML::Field');

sub initialize {
    my $self = shift;
    $self->{_autoloadable}->{auto}++;
    return $self;
}

sub creation_html {
    my $self = shift;

    return ( $self->name, '<!-- auto generated primary key -->' )
      if ( $self->{auto} );

    return $self->editable_html;
}

sub editable_html {
    my $self = shift;
    croak 'All hidden fields must have a value'
      unless defined $self->value;
    my $tag =
        '<input type="hidden" name="'
      . $self->name
      . '" value="'
      . $self->value . '"'
      ;
    $tag .= HTML::Field->xhtml ? '/>' : '>';
    return ( $self->name, $tag );
}

sub readonly_html {
    my $self = shift;
    return ($self->name, '<!-- Hidden field -->');
}

#####################################################################
#####################################################################
#####################################################################

package HTML::Field::Password;

use strict;
use vars qw(@ISA);

@ISA = ('HTML::Field');

sub initialize {
    my $self = shift;
    push @{ $self->{_valued_html_attr} }, 'size', 'maxlength';
    foreach (qw{size maxlength}) {
        $self->{_autoloadable}->{$_}++;
    }
    return $self;
}

sub editable_html {
    my $self = shift;
    my $field =
        '<input type="password" name="'
      . $self->name . '"'
      . $self->_editable_html
      ;
    $field .= ' value="' . $self->value . '"' if defined $self->value;
    $field .= HTML::Field->xhtml() ? '/>' : '>';
    return ( $self->name, $field );
}

sub readonly_html {
    return '*****';
}

#####################################################################
#####################################################################
#####################################################################

package HTML::Field::Select;

use Carp;
use strict;
use vars qw(@ISA);

@ISA = ('HTML::Field');

sub initialize {
    my $self = shift;
    push @{ $self->{_valued_html_attr} },    'size';
    push @{ $self->{_nonvalued_html_attr} }, 'multiple';
    foreach (qw{size multiple options labels}) {
        $self->{_autoloadable}->{$_}++;
    }

    croak "HTML::Field::Select object does not contain options\n"
      unless ( defined $self->options
        && ref( $self->options ) eq 'ARRAY' );

    croak "HTML::Field::Select labels should be a hash reference\n"
      if ( defined $self->labels && ref( $self->labels ) ne 'HASH' );

    return $self;
}

sub editable_html {
    my $self = shift;

    croak "HTML::Field::Select object does not contain options\n"
      unless ( defined $self->options
        && ref( $self->options ) eq 'ARRAY' );

    croak "HTML::Field::Select labels should be a hash reference\n"
      if ( defined $self->labels && ref( $self->labels ) ne 'HASH' );

    my %labels;
    if ( defined $self->labels ) {
        %labels = %{ $self->labels };
    }

    my $field =   '<select name="' 
                . $self->name 
                . '"' 
                . $self->_editable_html
                . '>'
                ;

    foreach my $option ( @{ $self->options } ) {
        $field .= "\n\t<option value=\"$option\"";
        if ( defined $self->value && $self->value eq $option ) {
            $field .=
              HTML::Field->xhtml
              ? ' selected="selected"'
              : ' selected';
        }
        $field .= '>';
        if ( defined $labels{$option} ) {
            $field .= "$labels{$option}</option>";
        }
        else {
            $field .= "$option</option>";
        }
    }
    $field .= "\n</select>";
    return ( $self->name, $field );
}

sub readonly_html {
    my $self = shift;
    return '-----' unless defined $self->value;
    if (defined $self->labels && exists $self->labels->{ $self->value }) {
        return ( $self->name, $self->labels->{ $self->value } );
    }
    else {
        return ( $self->name, $self->value );
    }
}


#####################################################################
#####################################################################
#####################################################################

package HTML::Field::Radio;

use Carp;
use strict;
use vars qw(@ISA);

@ISA = ('HTML::Field');

sub initialize {
    my $self = shift;

    $self->{_autoloadable}->{options}++;
    croak "A radio button must have an array of 'options'"
      unless ( defined $self->options
        && ref( $self->options ) eq 'ARRAY' );

    $self->{readonly_tags} = { true => '+', false => '-' }
      unless defined $self->{readonly_tags};

    return $self;
}

sub readonly_tags {
    my $self = shift;
    if (@_) {
        my %args = @_;
        croak 
            "read_only_tags must be called with the following arguments:\n"
          . "true => 'representation t', false => 'representation f'"
          unless ( exists $args{true} && exists $args{false} );
        $self->{readonly_tags} = \%args;
        return;
    }

    return $self->{readonly_tags};
}

sub editable_html {
    my $self = shift;

    croak "HTML::Field::Radio object does not contain options\n"
      unless ( defined $self->options
        && ref( $self->options ) eq 'ARRAY' );
    
    my %tags;
    foreach my $opt ( @{ $self->options } ) {
        my $name = $self->name . '_' . $opt;
        $tags{$name} = '<input type="radio" name="' 
            . $self->name . '" option="' . $opt . '"'
            . $self->_editable_html
            ;
        if ( $self->value eq $opt ) {
            $tags{$name} .= ' checked';
            $tags{$name} .= q{="checked"} if $self->xhtml;
        }
        $tags{$name} .= $self->xhtml ? '/>' : '>';
    }
    
    return %tags;
}

sub readonly_html {
    my $self = shift;
    
    my %tags;
    foreach my $opt ( @{ $self->options } ) {
        my $name = $self->name . '_' . $opt;
        $tags{$name} = 
            $self->value eq $opt
                ? $self->readonly_tags->{true}
                : $self->readonly_tags->{false}
                ;
    }
    
    return %tags;
}

#####################################################################
#####################################################################
#####################################################################

package HTML::Field::Textarea;

use strict;
use vars qw(@ISA);

@ISA = ('HTML::Field');

sub initialize {
    my $self = shift;
    push @{ $self->{_valued_html_attr} }, 'cols', 'rows';
    foreach ( 'cols', 'rows' ) {
        $self->{_autoloadable}->{$_}++;
    }
    return $self;
}

sub editable_html {
    my $self = shift;
    my $field =
      '<textarea name="' . $self->name . '"' . $self->_editable_html . '>';
    $field .= $self->value if defined $self->value;
    $field .= '</textarea>';
    return ( $self->name, $field );
}

#####################################################################
#####################################################################
#####################################################################

package HTML::Field::Textfield;

use strict;
use vars qw(@ISA);

@ISA = ('HTML::Field');

sub initialize {
    my $self = shift;
    push @{ $self->{_valued_html_attr} }, 'size', 'maxlength';
    foreach (qw{size maxlength auto primary_key}) {
        $self->{_autoloadable}->{$_}++;
    }
    return $self;
}

sub creation_html {
    my $self = shift;

    return ( $self->name, '<!-- auto generated primary key -->' )
      if ( $self->{auto} );

    return $self->_generate_html;
}

sub editable_html {
    my $self = shift;

    # If this field is a primary key or if it is marked as 'auto'
    # and has a value, then it should not be editable but it should return
    # its read-only value and a hidden field:
    if (  ( defined $self->{primary_key} || defined $self->{auto} )
        &&  defined $self->value )
    {
        my $field = $self->value
          . ' <input type="hidden" name="'
          . $self->name
          . '" value="'
          . $self->value
          . '"'
          ;
        $field .= HTML::Field->xhtml ? '/>' : '>';
        return ( $self->name, $field );
    }

    return $self->_generate_html;
}

# Finally, this method generates the standard text field
sub _generate_html {
    my $self = shift;
    my $field = '<input type="text" name="' 
                . $self->name . '"' 
                . $self->_editable_html
                ;
    $field .= ' value="' . $self->value . '"' if defined $self->value;
    $field .= HTML::Field->xhtml() ? '/>' : '>';
    return ( $self->name, $field );
}

1;

=pod

=head1 NAME

HTML::Field - Generation of HTML form elements

=head1 SYNOPSIS

 use HTML::Field;

 ########## Creation of Field objects ##############
 
 # A text field:
 my $field1 = HTML::Field->new('Textfield',
                  name      => 'fieldname',
                  value     => 'current value',
                  default   => 'default value',
                  size      => 15,
                  maxlength => 15 );

 # A Pasword field (has the same attributes as 'Textfield'):
 my $field2 = HTML::Field->new('Passwd',
                  name      => 'fieldname',
                  value     => 'current value',
                  default   => 'default value',
                  size      => 15,
                  maxlength => 15 );
 
 # A hidden field:
 my $hidden = HTML::Field->new('Hidden',
                  name      => 'sid',
                  value     => 'cgiasf25k',
                  default   => undef );
 
 # A text area:
 my $area = HTML::Field->new('Textarea',
                  name      => 'address',
                  cols      => 40,
                  rows      => 4 );
 
 # A 'select' tag. Options are given in an array reference; labels are  
 # given in a hash keyed by the options: 
 my $select = HTML::Field->new('Select',
                  name      => 'select_color',
                  options   => [qw(red yellow brown)],
                  default   => 'red',
                  labels    => {red    => 'Color of apples',
                                yellow => 'Color of mangos!',
                                brown  => 'Color of chocolate'},
                  multiple  => undef,  # Multiple is either true or false
                  size      => 1 );    # Size of select box
                  
 # A radio button. Note that it will generate the HTML for all of its
 # options, and those will be named as 'name_option'
 my $radio_buttons = HTML::Field->new('Radio',
                  name      => 'Flavors',
                  options   => [qw(Lemon Strawberry Grapefruit)],
                  default   => 'Grapefruit' );

 # A single checkbox:
 my $checkbox = HTML::Field->new('Checkbox', 
                  name      => 'Additional',
                  option    => 'Strawberry',
                  default   => 1,
                  read_only_tags => { true => 'X', false => 'o'});
                  
 # Render editable HTML
 my ($key, $value) = $field->editable_html;
 
 # Render read-only value
 ($key, $value) = $field->readonly_html;
 
 # Render editable HTML for a new element
 ($key, $value) = $field->creation_html;
 
 # Set a field's value from a CGI object, hash reference or scalar:
 my $value = $field->value($cgi);
 
 # or, get the filed's value:
 $value = $field->value;
 
 
 # The 'read_only_tags' attribute sets the representation of a
 # check box or of radio buttons for a 'read only' rendering. 
 # This feature can be used to load different images to represent
 # 'checked' radio buttons or check boxes.
 
 # Primary Key text field:
 my $field1 = HTML::Field->new('Textfield',
                  name        => 'login',
                  size        => 15,
                  maxlength   => 15,
                  primary_key => 1 );
                  
 # When a text field is marked as 'primary' key, then
 # it will not be editable once it has a value. This means that if you 
 # are displaying an empty form this will be an editable text field, 
 # but if you are displaying a database record for edition, then this 
 # field will not be editable and it will also be present as a hidden
 # field in order to get sent back to the script.
 
 # Primary key autogenerated by the database:
 my $serial = HTML::Field->new('Textfield',
                  name        => 'company_id',
                  size        => 4,
                  maxlength   => 4,
                  auto        => 1 );
                  
 # The same as above applies if the field value is generated by the 
 # database. In that case, the  value will never be editable; if the 
 # field has no value then a place holder will be returned instead. 

=head1 DESCRIPTION

HTML::Field objects are able to read their values from CGI objects, hash  references or plain scalars and then render those values as HTML fields or simple read-only HTML. They are meant to ease the interface between CGI, databases and templates.

IMPORTANT NOTE: This module does not validate the values of any HTML attributes that you supply.

See HTML::FieldForm for a class that works on sets of HTML::Fields.

=head1 COMMON ATTRIBUTES

=head2 Common functional attributes

There are three I<functional> attributes for  all Field objects: C<name>, C<value> and C<default>. By functional, I mean that these attributes have other uses than solely appearing in HTML. C<value> and C<default> have accessor/mutators named after them; C<name> is read-only and must be set during creation.

=head3 C<name>

Of the three common, functional attributes only C<name> is required. C<name> will be used for the following important things:

=over

=item 1. To look for the field value in a hash or a CGI object

=item 2. As the key in the hashes returned by the html methods

=item 3. As the name of the html tags produced

=back

So, if you are using HTML::Template, it is adviceable to name the parameters of your template the same as the fields you will use to populate it.

=head3 C<value> and  C<default>

These two attributes define the value of the Field objects in different stages of their existance. If you include a C<default> for an object, it will be the value that will be used since object creation until it is explicitly changed by C<value>. The C<reset_value> method will set C<value> equal to C<default>.

You can feed C<value> with a hash reference, a CGI object or a scalar value to set the value of a given field:

 $field->value($cgi);
 $field->value($hash_ref);
 $field->value(4);

=head2 Common HTML Attributes

Several HTML attributes can be used within all field tags.  There are two kinds of HTML attributes: Those which can take a value and those which are just true or false. For those which can have a value, their value can be any scalar and it will simply be inculded in the field tag.

All of these attributes may be set during object creation and also using their accessor/mutator (implemented via AUTOLOAD).

The following HTML attributes may be used with all of the HTML::Field classes:

=over

=item accesskey

=item id

=item title

=item class

=item style

=item lang

=item dir

=item tabindex

=item disabled (Boolean)

=item readonly (Boolean)

=back

Each HTML::Field class may have its own, particular attributes. See below.

=head1 COMMON METHODS

Besides the accessor/mutator methods explained above, there are three methods common to every Field object:

=over

=item $field->reset_values

Makes C<value> equal to C<default>.

=item %hash = $field->editable_html

The returned hash will have the field's name as key and its HTML field tag as value. It returns a hash because this way it is simpler to include it in a template (think HTML::Template). In this case, you can use it like this:

 $template->param($field->editable_html);

=item %hash = $field->readonly_html

Same as above, except that the HTML will not be a form tag but only a read-only HTML representation of the field's value. Usually this read-only HTML is simply the value of the field. 

For the checkboxes and radio buttons, it is possible to have images or any other mark up to display 'true' and 'false' states for reading via the C<readonly_tags> attribute; you can see it in the SYNOPSIS. This attribute has its accessor/mutator of the same name.

=item %hash = $field->creation_html

This method will return an empty HTML field for edition. Normally this method should be used when creating a new record in a database, as it will allow for the edition of fields marked as 'primary_key' (not for 'auto'). See the next section for an extended explanation.

=back

=head2 ATTRIBUTES C<primary_key> and C<auto>

If a form is displayed for the entry of a new record, then there are two scenarios regarding primary keys: 

=over

=item C<auto> -- Primary key is generated by the database or application

In this case the system generates a value for the primary key prior to its insertion in the database. This value will not exist when the empty form is served to the client for the first time, so it should not be included. However, it will exist and is needed if the record is requested for updating. In this case it will be sent in a non-editable form, followed by a hidden field (in the case of text fields). Think of using a hidden field for this case.

=item C<primary_key> -- Primary key is entered by the user

If the primary key of a record will be supplied by the user, then the field must be empty and editable when the form is first displayed. Once the record exists the primary key will be sent in a read-only form followed by a hidden  field. This way the primary key will be present in the data sent back to the server for updating the database. 

Note that because the field needs to be editable for record creation, a hidden field cannot be marked as primary key.

=back

In summary, calling C<creation_html> on a field marked as C<primary_key> will display an editable field. Calling C<editable_html> will return a read-only value followed with a hidden field.

Calling C<creation_html> on a field marked as C<auto> will only display an HTML comment as a marker. Calling C<editable_html> will display a hidden field instead, and in the case of a text field, it will also display its value.

You can only mark text fields as 'primary_key'; text and hidden fields support 'auto'.

=head1 SUBCLASSES AND THEIR PARTICULAR ATTRIBUTES AND METHODS

=head2 HTML::Field::Textfield

=head3 ATTRIBUTES

These attributes are optional. They have accessor/mutator methods (via AUTOLOAD). 

=over

=item size

=item maxlength

=item primary_key I<(Not an HTML attribute; see explanation above)>

=item auto I<(Not an HTML attribute; see explanation above)>

=back

=head2 HTML::Field::Hidden

Fields of this class must have a value when issueing editable HTML or they will raise an exception.

These fields may be marked as C<auto>, but not as C<primary_key>.

=over

=item auto I<(Not an HTML attribute; see explanation above)>

=back

=head2 HTML::Field::Password

=head3 ATTRIBUTES

These attributes are optional. They have accessor/mutator methods (via AUTOLOAD). 

=over

=item size

=item maxlength

=back

=head2 HTML::Field::Textarea

=head3 ATTRIBUTES

These attributes are optional. They have accessor/mutator methods (via AUTOLOAD). 

=over

=item cols

=item rows

=item wrap

=back

=head2 HTML::Field::Checkbox

This class is useful to implement single checkboxes; in other words, checkboxes that have their own name.

=head3 ATTRIBUTES

These attributes are optional. They have accessor/mutator methods (via AUTOLOAD). 

=over

=item readonly_tags

This attribute can take a hash with the keys 'true' and 'false', which should point to read-only representations of checked (true) or not checked (false) fields. For example:

 $field->readonly_tags(
        true  => '<img src="checked.png"     alt="Checked"/>',
        false => '<img src="not_checked.png" alt="Not checked"/>',
 );
 
Default is '+' for true and '-' for false.
 
=back

=head2 HTML::Field::Select

=head3 ATTRIBUTES

These attributes have accessor/mutator methods (via AUTOLOAD). 

=over

=item size -- Optional

=item multiple -- Optional I<(true or false only)>

=item options -- Required

Array reference of options.

=item labels -- Required

C<labels> will accept a hash of labels keyed by option.

=back

=head2 HTML::Field::Radio

Class to create radio button fields. A single object will generate as many radio buttons as options it has. These buttons will be named like this:

 field_option

So, following the example in the synopsis, we would have: I<Flavors_Lemon>,
I<Flavors_Strawberry>, and I<Flavors_Grapefruit>.

=head3 ATTRIBUTES

These attributes have accessor/mutator methods (via AUTOLOAD). 

=over

=item options -- Required

Array reference of options.

=item readonly_tags

See HTML::Field::Checkbox for an explanation.

=back

=head1 SEE ALSO

HTML::FieldForm is a module that manages sets of HTML::Field objects.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Julio Fraire

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.

=cut

# $Id: Field.pm,v 1.18 2009/06/27 22:46:03 julio Exp $
# $Log: Field.pm,v $
# Revision 1.18  2009/06/27 22:46:03  julio
# Removed attribute 'wrap' from Textarea
#
# Revision 1.17  2009/05/27 23:21:45  julio
# Updated $VERSION
#
# Revision 1.16  2009/05/27 22:51:10  julio
# If an object other than CGI is given to the value method, it is
# assumed to work as a hash reference. This includes hash references.
# This is to work with DBIx::DataModel based classes.
# Miscellaneous changes to the documentation.
#
# Revision 1.15  2009/05/01 22:05:31  julio
# Fixed problem with hidden fields' readonly_html.
#
# Revision 1.14  2009/05/01 21:50:23  julio
# Fixed bug in checkbox. It was not returning the html field correctly
# when the field was valued.
#
# Revision 1.13  2009/05/01 05:13:29  julio
# Completed documentation on each subclass and fixed Hidden, Textfield
# and Checkbox to conform to the new docs.
#
# Revision 1.12  2009/04/28 20:18:45  julio
# Removed Radiobutton.
#
# Revision 1.11  2009/04/28 20:15:54  julio
# Added HTML::Field::Radio
#
# Revision 1.10  2009/04/27 04:13:31  julio
# After a looong time!
#
# Revision 1.9  2007/10/13 03:51:30  julio
# HTML::Field::Hidden no longer needs to know its value at creation time.
#
# Revision 1.8  2007/09/27 05:59:42  julio
# Added documentation regarding 'default' for HTML::Field::Checkbox.
# Fixed redundant condition in _editable_html.
#
# Revision 1.7  2007/09/26 04:41:22  julio
# Added xhtml switch! I still need to do tests
# and documentation; the current tests passed OK.
#
# Revision 1.6  2007/08/12 02:24:58  julio
# Added method creation_html, docs and tests
#
# Revision 1.5  2007/08/10 02:57:17  julio
# Integrated POD into this file
#
# Revision 1.4  2007/08/10 01:49:45  julio
# Only ran perltidy on this file
#
# Revision 1.3  2007/08/10 01:26:32  julio
# Added logic to implement primary_key and auto into text fields
#
# Revision 1.2  2006/12/10 01:33:11  julio
# Improved test coverage for parent class
#
# Revision 1.1  2006/12/10 00:34:52  julio
# Initial revision
#
# Revision 0.0  2006/12/01 03:26:05  julio
# Initial revision

