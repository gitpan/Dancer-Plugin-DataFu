# ABSTRACT: Dancer HTML Form and Grid/Table engine with Input Validation
package Dancer::Plugin::DataFu;
BEGIN {
  $Dancer::Plugin::DataFu::VERSION = '0.0100';
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

version 0.0100

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
Oogly::Aagly, please examine that POD (documentation) for a more indepth look at
configuration.

=head1 CONFIGURATION

    plugins:
      DataFu:
        form:
          templates: views/datafu
          profiles: data/profiles
        grid:
          templates: views/datafu
          profiles: data/profiles

=head1 FORM PROFILES

    ... myapp/profiles/user.pl
    
    # user validation profile

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

Profiles are where you would put all of your data input constraints and
validation rules. Form rending and input validation is done almost indentically
to that of CPAN module Oogly::Aagly, please examine that POD (documentation) for
a more indepth look at configuration. All profiles in the specified 'profiles'
directory are loaded automatically for DRY (don't repeat yourself) purposes,
allowing you to mix fields from different profiles. The field uses in rendering
and validation is stored and referenced using the profile name and field name
together seperated with a single period. i.e. The login field example above would
be referenced as ...

    form->validate('user.login');
    form->render('form', '/action', 'user.login');

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

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

