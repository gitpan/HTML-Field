package HTML::FieldForm;

use HTML::Field;
use Carp;
use strict;

# Constructor method. Shall receive an array ref of HTML::Field objects.
sub new {
    my $class   = shift;
    my $fields  = {@_};
    
    my %self;
    foreach my $name (keys %$fields) {
        my $type = $fields->{$name}[0];
        my $args = $fields->{$name}[1];
        $args->{name} = $name;
        my $field;
        eval {
            $field = HTML::Field->new($type, %$args);
        };
        croak "Error while creating field $name (class $type): $@"
            if $@;
        $self{$name} = $field;
    }
    return bless \%self, $class;
}

# This method will return the names of all the fields in the form:
sub names {
    my $self = shift;
    return keys %$self;
}

# This method shall receive a hash reference or CGI object to be passed to
# the different Field objects in order for them to read their values.
# Returns nothing.
sub set_values {
    my $self   = shift;
    my $values = shift;
    foreach my $field ( keys %$self ) {
        $self->{$field}->value($values);
    }
    return;
}

# This method shall return the values of the different Field objects as a 
# hash. It is planned to be useful for generating SQL statements by
# SQL::Abstract.
sub get_values {
    my $self   = shift;
    my %result = ();
    foreach my $field ( keys %$self ) {
        $result{ $field } = $self->{$field}->value;
    }
    return %result;
}

# This method will take every field value to its default. It returns 
# nothing.
sub reset_values {
    my $self = shift;
    foreach my $field ( keys %$self ) {
        $self->{$field}->reset_value;
    }
    return;
}

# This method will return a hash containing the editable html 
# (form elements).
# The keys are the names normally given to the HTML::Template parameters or
# form elements. Note that a single field might use several form elements
# (a date or a radio buttons group, for example)
sub editable_html {
    my $self   = shift;
    my %result = ();
    foreach my $field ( keys %$self ) {
        $result{ $field } = $self->{$field}->editable_html;
    }
    return %result;
}

# This method will return a hash containing the read-only html (form elements).
# The keys are the names normally given to the HTML::Template parameters or
# form elements. Note that a single field might use several form elements
# (a date or a radio buttons group, for example)
sub readonly_html {
    my $self   = shift;
    my %result = ();
    foreach my $field ( keys %$self ) {
        $result{ $field } = $self->{$field}->readonly_html;
    }
    return %result;
}

# This method will return a hash containing the editable html (form elements).
# The keys are the names normally given to the HTML::Template parameters or
# form elements. Note that a single field might use several form elements
# (a date or a radio buttons group, for example).
sub creation_html {
    my $self = shift;
    my %result = ();
    foreach my $field ( keys %$self ) {
        $result{ $field } = $self->{$field}->creation_html;
    }
    return %result;
}

# Sets xhtml output or plain html output from HTML::Field. Default is HTML.
# Returns $self to enable chained calls
sub set_xhtml {
    my ($self, $xhtml) = @_;    
    HTML::Field->xhtml($xhtml);
    return $self;
}

# If used, it will add id="name" on every field. Useful for CSS styling
# and using <label>.
# Returns $self to enable chained calls
sub add_id {
    my ($self, $ids) = @_;
    
    foreach my $field (keys %$self) {
        $self->{ $field }->id( $self->{$field}->name );
    }
    
    return $self;
}

1;

=pod

=head1 NAME

FieldForm -- Handle HTML forms with Field objects

=head1 SYNOPSIS

   use HTML::FieldForm;
   use HTML::Field;
   
   # Object constructor
   my $form = HTML::FieldForm->new(    
     part_number      => [ 'Textfield', {
                            primary_key => 1,
                       } ],
     description      => [ 'Textarea', {
                            cols        => 60,
                            rows        => 6,
                       } ],
     purchasing_code =>  [ 'Select', {
                            options     => \@purchasing_codes,
                            labels      => \%purch_codes_labels,
                       } ],
   );
   
   # The returned object is a hash of HTML::Field objects keyed by name:
   my $part_number = $form->{part_number};
   
   # Set the value of the fields from a hash ref
   my %values = (part_number => '16-0021', description => 'Brushplate');
   $form->set_values(\%values);

   # Set the value of the fields from a CGI object
   my $query = new CGI;
   $form->set_values($query);

   # Get the values of all the fields in a hash
   my %data = $form->get_values;
 
   # Reset all the field values to their defaults
   $form->reset_values;
   
   # Get a hash with editable or read only html (fieldname => html)
   # Specially useful for HTML::Template
   my %editable = $form->editable_html;
   my %readonly = $form->readonly_html;
   my %creation = $form->creation_html;
   
   # Request XHTML instead of HTML
   $field_form->set_xhtml(1); # Gets xhtml
   $field_form->set_xhtml(0); # Gets html (default)
   
   # Request the addition of an ID selector for each form field 
   # (same as its name)
   $field_form->add_id;
   
   # These two last methods return the HTML::FieldForm object, so that
   # you can say:
   %editable = $field_form->xhtml(1)->add_id->editable_html;
   
=head1 DESCRIPTION

The goal of this simple module is to perform common actions over a set
of HTML form fields in order to get rid of some of the tedious of scripting
CGI.

=head1 AUTHOR

Julio Fraire, E<lt>jfraire@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Julio Fraire

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

# $Id: FieldForm.pm,v 0.6 2009/06/05 05:27:50 julio Exp $
# $Log: FieldForm.pm,v $
# Revision 0.6  2009/06/05 05:27:50  julio
# Added set_xhtml and add_id methods.
#
# Revision 0.5  2009/06/05 00:42:46  julio
# Added use HTML::Field, since the new "new" method will create
# the HTML::Field objects itself and there would be no need to use
# HTML::Field from user code.
#


