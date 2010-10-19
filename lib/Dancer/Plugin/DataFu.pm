# ABSTRACT: Dancer HTML Form and Grid/Table engine with Input Validation
package Dancer::Plugin::DataFu;
BEGIN {
  $Dancer::Plugin::DataFu::VERSION = '0.0111';
}

use strict;
use warnings;
use Dancer qw/:syntax/;
use Dancer::Plugin;
use Dancer::Plugin::DataFu::Form;
use Dancer::Plugin::DataFu::Grid;

my  $settings = plugin_setting;

register 'form' => sub {
    return Dancer::Plugin::DataFu::Form->new($settings);
};

register 'grid' => sub {
    return Dancer::Plugin::DataFu::Grid->new($settings);
};


register_plugin;

1;

__END__
=pod

=head1 NAME

Dancer::Plugin::DataFu - Dancer HTML Form and Grid/Table engine with Input Validation

=head1 VERSION

version 0.0111

=head1 SYNOPSIS

    # form rendering and validation

    get 'login' => sub {
        return form->render('user.login', 'user.password');
    };
    
    post 'login' => sub {
        my $input = form;
        redirect '/dashboard' if $input->validate('user.login', 'user.password');
        return $input->render('user.login', 'user.password');
    };

=head1 DESCRIPTION

Dancer::Plugin::DataFu is an HTML form and table rendering engine with data
validation support. All HTML elements are rendered using TT (Template-Toolkit) 
templates, which can be copied to your application folder and altered as you see fit 
providing the ultimate in flexibility when rendering HTML and Validating User Input.
Form rending and input validation is done almost indentically to that of CPAN module
L<Oogly::Aagly>, please examine that POD (documentation) for a more indepth look at
configuration.

=head1 WHY DataFu IS GREAT

What Dancer::Plugin::DataFu does is complex, but what it asks the user/developer
to do is simple. This is what makes Dancer::Plugin::DataFu awesome amongst other
things. Unlike HTML::FormFu, CGI::FormValidator, Form::Sensible, HTML::FormHandler
and a whole host of other solutions, Dancer::Plugin::DataFu approaches HTML form
rendering and data input validation in a very different manner. First and most
importantly, data input (referred to as fields) are compartmentalized from the
start. Meaning you define each field individually then group them within a
profile, like columns exist in database tables, fields exist profiles but can be
mixed together with other fields from other profiles to generate an array of
forms without having to define each form specifically.

Second and of equal import, Dancer::Plugin::DataFu uses Template-Toolkit to
define, style and render forms. All standard HTML form elements have pre-made
templates that ship with Dancer::Plugin::DataFu and exist in your local Perl
library. These template have been designed to automatically display inline error
messages if form valdiation fails and also remembers posted form data, etc. If
the default form style, error messages, sticky form functionality, etc are not
enough for you, I have included a command-line utility to copy
Dancer::Plugin::DataFu template to your current working directory for you
manipulating pleasure, e.g. 

    $ dancer-datafu
    ... copied HTML template from ... to ...

Form elements can be rendered individually or as part of a form, custom form
elements can be created and registered for automatic use in form generation,
your template directory can be changed programmatically at runtime based on
conditions, environment, etc.

All this is done while only requiring the developer to specify to most basic
parameters.

=head1 CONFIGURATION

    plugins:
      DataFu:
        form:
          profiles: ./
        grid:
          profiles: ./

Form and Grid profiles are like classes that encapsulate the individual fields
required to render form or table elements. Profile are perl .pl files which
returns a hashref that the rendering engines use to process your request. As
stated above, the Dancer::Plugin::DataFu form and grid HTML TT templates can be
copied to your current working directory for customization in which case you
will need to tell the plugin where those templates are being stored.

    plugins:
      DataFu:
        form:
          templates: views/datafu
          profiles: profiles
        grid:
          templates: views/datafu
          profiles: profiles/table

=head1 FORM PROFILES

    ... myapp/profiles/user.pl
    
    # form profile example

    our $profile = {
        
        'login' => {
            label    => 'user login',
            required => 1,
            element  => {
                type => 'input_text'
            }
        },
        
        'password' => {
            label    => 'user password',
            required => 1,
            element  => {
                type => 'input_text'
            }
        }
        
    };

Form profiles are where you would put all of your data input constraints and
validation rules. Form rending and input validation is done almost indentically
to that of CPAN module L<Oogly::Aagly>, please examine that POD (documentation)
for a more indepth look at configuration. All profiles in the specified 'profiles'
directory are loaded automatically for DRY (don't repeat yourself) purposes,
allowing you to mix fields from different profiles. The fields used in rendering
and validation are stored and referenced using the profile name and field name
together seperated with a single period (.), i.e. The login field example above
would be referenced as ...

    form->validate('user.login'); #profile: user, field: login

Requiring only the form name, action URL and a list of fields (profile.fieldname),
Dancer::Plugin::DataFu makes form validation and generation fun and easy.

    form->render('form', '/action', 'user.login');

=head2 FORM PROFILE SPECIFICATION

A form profile is a Perl file (.pl file specifically) that returns a hashref
which will be used to configure the form rendering engine that evals it. A form
profile can have the following definitions.

    # consider to following
    our $profile = {
        
        'field_name' => {
            ...
        },
        
    };

    # each field may contain the following definitions
    label      => 'human-readable field name'
    error      => 'override the system standard error(s)'
    
    required   => 1
    min_length => 2
    max_length => 10
    ref_type   => 'array',
    regex      => '^\d+$'
    
    filters => [
        'trim',
        'strip',
        'lowercase',
        'uppercase',
        'camelcase',
        'alphanumeric',
        'numeric',
        'alpha',
        'digit',
        sub { # do something with @_ }
    ]
    
    validation => sub {
        my ($self, $field, $all_parameters) = @_;
        ...
    }

=head2 FORM TEMPLATES

If you are familiar with TT (Template-Toolkit) then you already understand that
you usually want to pass a few variables to the rendering engine when processing
a template, if you didn't already know that, you do now. Each form template
element is passed the following variables...

    my $template_variable_object = {
        name  => 'form name',
        url   => 'form url',
        form  => $form_class_object,
        field => $field_object_context,
        this  => 'field name',
        vars  => $additional_custom_variables_hashref
    };

=over

=item form.tt

    ... form.tt
    This template is a wrapper that encapsulates the selected form elements
    rendered.

=item input_checkbox.tt

    ... input_checkbox.tt
    
    'profile.languages' => {
        element => {
            type => 'input_checkbox',
            options => [
                { value => 100, label => 'English' },
                { value => 101, label => 'Spanish' },
                { value => 102, label => 'Russian' },
            ]
        },
        default => 100
    };
    
    ... or ...
    
    'profile.languages' => {
        label => 'World Languages',
        element => {
            type => 'input_checkbox',
            options => {
                { value => 100, label => 'English' },
                { value => 101, label => 'Spanish' },
                { value => 102, label => 'Russian' },
            }
        },
        default => [100,101]
    };

=item input_file.tt

    ... input_file.tt
    
    'profile.avatar_upload' => {
        element => {
            type => 'input_file'
        }
    };

=item input_hidden.tt

    ... input_hidden.tt
    
    'profile.sid' => {
        element => {
            type => 'input_hidden'
        },
        value => $COOKIE{SID} # or whatever
    };

=item input_password.tt

    ... input_password.tt
    
    'profile.password_confirm' => {
        element => {
            type => 'input_password'
        }
    };

=item input_radio.tt

    ... input_radio.tt
    
    'profile.payment_method' => {
        element => {
            type => 'input_radio',
            options => [
                { value => 100, label => 'Visa' },
                { value => 101, label => 'MasterCard' },
                { value => 102, label => 'Discover' },
            ],
            default => 100
        }
    };

=item input_text.tt

    ... input_text.tt
    
    'profile.login' => {
        element => {
            type => 'input_text'
        }
    };

=item select.tt

    ... select.tt
    
    'profile.payment_terms' => {
        element => {
            type => 'select',
            options => [
                { value => 100, label => 'Net 10' },
                { value => 101, label => 'Net 15' },
                { value => 102, label => 'Net 30' },
            ],
        }
    };

=item select_multiple.tt

    ... select_multiple.tt
    
    'profile.user_access_group' => {
        element => {
            type => 'select_multiple',
            options => [
                { value => 100, label => 'User' },
                { value => 101, label => 'Admin' },
                { value => 102, label => 'Super Admin' },
            ],
        }
    };

=item textarea.tt

    ... textarea.tt
    
    'profile.myprofile_greeting' => {
        element => {
            type => 'textarea',
        }
    };

=back

=head1 GRID PROFILES

    ... myapp/profiles/table/user.pl

    our $profile = {
        
        'header'  => 'example table header',
        'columns' => [
            {
                header  => 'ID',
                bindto  => 'id',
                element => {
                    type => 'input_checkbox'
                }
            },
            {
                header => 'Column One',
                bindto => 'col1',
            },
            {
                header => 'Column Two',
                bindto => 'col2',
            },
            {
                header => 'Action',
                data   => sub {
                    my ($self, $row) = @_;
                    return $row->{col1};
                },
            }
        ],
        'navigation' => sub {
            my ($self, $dataset) = @_;
            return 'Found ' . @{$dataset} . ' records';
        }
        
    };

Grid profiles are where you would put all of your table configuration information.
All grid profiles in the specified directory are loaded automatically allowing you
easily select from different profiles. Like forms, rendering HTML tables is very
straightforward requiring only a table name, dataset (arrayref of hashrefs), and
the name of the profile. e.g.

    my $dataset = [
        { id => 100, col1 => 'column1a', col2 => 'column2a' },
        { id => 101, col1 => 'column1b', col2 => 'column2b' },
        { id => 102, col1 => 'column1c', col2 => 'column2c' },
        { id => 103, col1 => 'column1d', col2 => 'column2d' },
        { id => 104, col1 => 'column1e', col2 => 'column2e' },
        { id => 105, col1 => 'column1f', col2 => 'column2f' },
        { id => 106, col1 => 'column1g', col2 => 'column2g' },
        { id => 107, col1 => 'column1h', col2 => 'column2h' },
        { id => 108, col1 => 'column1i', col2 => 'column2i' },
        { id => 109, col1 => 'column1j', col2 => 'column2j' },
    ];

    grid->render('name', $dataset, 'user');

=head2 GRID PROFILE SPECIFICATION

A grid profile is a Perl file (.pl file specifically) that returns a hashref
which will be used to configure the grid rendering engine that evals it. A grid
profile can have the following definitions.

    # consider to following
    our $profile = {
        
        'header' => '',
        'columns' => [...],
        'navigation' => sub { ...}
        
    };

    # header obviously describes the table and renders a table header row
    # if omitted, does not render

    # columns is an arrayref where each element is a hashref that may
    # contain the following definitions
    
    header => 'column name'
    bindto => 'dataset column key'
    data => sub {
        my ($self, $row) = @_
        # hint: return <a href="?action=edit&id=$row->{id}">Edit</a>
        ...
    }
    element => {
        type => 'input_checkbox',
        value => '1'
    }

=head2 GRID TEMPLATES

If you are familiar with TT (Template-Toolkit) then you already understand that
you usually want to pass a few variables to the rendering engine when processing
a template, if you didn't already know that, you do now. Each form template
element is passed the following variables...

    my $template_variable_object = {
        name  => 'grid name',
        prof  => $grid_profile_object,
        colm  => $column_object_context,
        vars  => $additional_custom_variables_hashref
    };

=over

=item table.tt

    ... table.tt
    This template is a wrapper that encapsulates the headers and row elements
    rendered.

=item tdata.tt

    ... tdata.tt
    This template is a wrapper that encapsulates any data not wrapped by another
    table template.

=item thead.tt

    ... thead.tt
    This template is uses to render the column headers.

=item theader.tt

    ... theader.tt
    This template is uses to render the table header.

=item tnavigation.tt

    ... tnavigation.tt
    This template is uses to render the header or footer navigation.

=item trow.tt

    ... trow.tt
    This template is a wrapper that encapsulates the current table row.

=back

=head1 METHODS

=head2 render

The render method returns compiled html for the form or grid object the called it.
Additionally you can pass a hashref of key/value pairs as the last argument to
render to include additional variables in the processing of the template.

    $self->render( 'form_name', '/form/action_url', @fields, \%more_vars );

=head2 render_control

The render_control method returns an HTML form element using the specified field name.
This is useful when you need to break out of the canned form rendering layout and
prefer to render the form fields individually.The render_control method may be
passed one or many form field names.

    $self->render_control('field_name');
    
    # return multiple form elements as an array
    $self->render_control(@fields);

=head2 templates

The templates method is used to define the relative path to where the HTML
element templates are stored.

    $form->templates('views/elements');

=head2 template

The template method is used to define the relative path to where the specified
form element template is stored.

    $form->template(input_text => 'elements/input_text.tt');

This method can also be used to specify the location of custom elements during
runtime.

    $form->template(js_tree => 'elements/js_tree.tt');

=head1 DISCLAIMER

I suppose I should mention that the form validation and rendering portion of this
package has been ported from L<Oogly::Aagly> which means that it has undergone a
lot more testing and design than the grid rendering portion. So I hope you will 
be a little patient, I'll make sure I catch up.

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

