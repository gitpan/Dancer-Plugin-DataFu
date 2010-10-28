# ABSTRACT: Dancer HTML Form renderer
package Dancer::Plugin::DataFu::Form;
BEGIN {
  $Dancer::Plugin::DataFu::Form::VERSION = '0.0121';
}

use strict;
use warnings;
use 5.008001;
use Template;
use Template::Stash;
use Array::Unique;
use Dancer::FileUtils;
use Hash::Merge qw/merge/;
use Oogly qw/:all !error !params/;
use Dancer qw/:syntax !error !params/;
use File::ShareDir qw/:ALL/;
use Data::Dumper::Concise qw/Dumper/;

{
    no warnings 'redefine';

    sub fields {
        my ($self, @fields) = @_;
        if (@fields) {
            if ("HASH" eq ref $fields[0]) {
                foreach my $field (%{$fields[0]}) {
                    $self->{data}->{fields}->{$field} = $fields[0]->{$field};
                }
            }
            else {
                my $fields = { @fields };
                foreach my $field (%{$fields}) {
                    $self->{data}->{fields}->{$field} = $fields->{$field};
                }
            }
        }
        return $self->{data}->{fields};
    }
    
    sub params {
        my ($self, @params) = @_;
        if (@params) {
            if ("HASH" eq ref $params[0]) {
                foreach my $param (%{$params[0]}) {
                    $self->{data}->{params}->{$param} = $params[0]->{$param};
                }
            }
            else {
                my $params = { @params };
                foreach my $param (%{$params}) {
                    $self->{data}->{params}->{$param} = $params->{$param};
                }
            }
        }
        return $self->{data}->{params};
    }

}

sub render {
    my ( $self, $name, $url, @fields ) = @_;
    my $form_vars = {};

    # check for form template vars
    if ( ref( $fields[@fields] ) eq "HASH" ) {
        $form_vars = pop @fields;
    }

    # use all established fields if none defined
    @fields = keys %{ $self->{data}->{fields} }
    unless @fields;

    my $counter    = 0;
    my @form_parts = ();
    foreach my $field (@fields) {
        $self->{data}->check_field($field);
        die "The field `$field` does not have an element directive"
          unless defined $self->{data}->{fields}->{$field}->{element};
        my $template = Template->new(
            INTERPOLATE => 1,
            EVAL_PERL   => 1,
            ABSOLUTE    => 1,
            ANYCASE     => 1
        );
        my $type = $self->{data}->{fields}->{$field}->{element}->{type};
        my $html = $self->temppath( $self->{templates}->{$type} );
        $html =
          $self->temppath(
            $self->{data}->{fields}->{$field}->{element}->{template} )
          if defined $self->{data}->{fields}->{$field}->{element}->{template};

        my $tvars = $self->{data}->{fields}->{$field};
        $tvars->{name} = $field;
        my $args = {
            name  => $name,
            url   => $url,
            form  => $self->{data},
            field => $tvars,
            this  => $field,
            vars  => $form_vars
        };
        $form_parts[$counter] = '';
        $template->process( $html, $args, \$form_parts[$counter] )
        || die $template->error;
        $counter++;
    }
    my $template = Template->new(
        INTERPOLATE => 1,
        EVAL_PERL   => 1,
        ABSOLUTE    => 1,
        ANYCASE     => 1
    );
    my $html = $self->temppath( $self->{templates}->{form} );
    my $args = {
        name    => $name,
        url     => $url,
        form    => $self->{data},
        content => join( "\n", @form_parts ),
        vars    => $form_vars
    };
    my $content;

    $template->process( $html, $args, \$content )
    || die $template->error;
    return $content;
}

sub render_control {
    my ( $self, @fields ) = @_;
    my $form_vars = {};

    # check for form template vars
    if ( ref( $fields[@fields] ) eq "HASH" ) {
        $form_vars = pop @fields;
    }

    my $counter    = 0;
    my @form_parts = ();
    foreach my $field (@fields) {
        $self->{data}->check_field($field);
        die "The field `$field` does not have an element directive"
          unless defined $self->{data}->{fields}->{$field}->{element};
        my $template = Template->new(
            INTERPOLATE => 1,
            EVAL_PERL   => 1,
            ABSOLUTE    => 1,
            ANYCASE     => 1
        );
        my $type = $self->{data}->{fields}->{$field}->{element}->{type};
        my $html = $self->temppath( $self->{templates}->{$type} );
        $html =
          $self->temppath(
            $self->{data}->{fields}->{$field}->{element}->{template} )
          if defined $self->{data}->{fields}->{$field}->{element}->{template};

        my $tvars = $self->{data}->{fields}->{$field};
        $tvars->{name} = $field;
        my $args = {
            form  => $self->{data},
            field => $tvars,
            this  => $field,
            vars  => $form_vars
        };
        $form_parts[$counter] = '';
        $template->process( $html, $args, \$form_parts[$counter] )
        || die $template->error;
        $counter++;
    }

    return @form_parts;
}

sub templates {
    my ( $self, $path ) = @_;
    return $self->{data}->{templates}->{directory} = $path;
}

{
    no warnings 'redefine';

    sub new {
        my $class    = shift;
        my $settings = shift;
        my $profiles = $settings->{form}->{profiles}
          || die 'No form profiles are configured in the config file';
        my @profiles =
          glob path( config->{appdir}, ( split /[\\\/]/, $profiles ), '*.pl' );
        my $self   = {};
        my $fields = {};

        foreach my $profile (@profiles) {
            next unless $profile;

            die "No such profile: $profile\n"   unless -f $profile;
            die "Can't read profile $profile\n" unless -r _;

            my ($profile_name) = $profile =~ /[\\\/]([\w\.]+)\.pl/;
            die "Could not generate a profile name for profile $profile"
              unless $profile_name;

            $fields->{$profile_name} = do $profile;
            die "Input profiles didn't return a hash ref: $@\n"
              unless ref $fields->{$profile_name} eq "HASH";
        }

        # message all profiles into a super fields hash for Oogly to process
        # Oogly::Oogly(mixins => {}, fields => $fields);

        my $globule = {};
        my $params  = params;
        foreach my $key ( keys %{$fields} ) {
            foreach my $field ( keys %{ $fields->{$key} } ) {
                $globule->{"$key.$field"} = $fields->{$key}->{$field};
            }
        }

        my $template_directory =
          $settings->{form}->{templates}
          ? path( config->{appdir}, $settings->{form}->{templates} )
          : module_dir('Dancer::Plugin::DataFu') . "/elements/";

        $self->{data} =
          Oogly::Oogly( mixins => {}, fields => $globule )->setup($params);
        $self->{profiles} = \@profiles;
        $self->{templates} = { directory => $template_directory };

        foreach my $tmpl ( glob path $template_directory, '*.tt' ) {
            my ( $file, $name ) = $tmpl =~ /.*[\\\/]((\w+)\.tt)/;
            $self->{templates}->{$name} = $file;
        }

        die "No TT HTML tempxlates where found under $template_directory"
          if keys %{ $self->{templates} } <= 1;
        
        $self->{settings} = $settings;
        
        bless $self, $class;
        return $self;
    }

    sub errors {
        my $self = shift;
        return $self->{data}->errors(@_);
    }

    sub validate {
        my ( $self, @fields ) = @_;
        die "Can't validate fields unless they're specied" if !@fields;
        return $self->{data}->validate(@fields);
    }

    sub template {
        my ( $self, $element, $path ) = @_;
        return $self->{data}->{templates}->{$element} = $path;
    }

    sub Oogly::check_mixin {
        my ( $self, $mixin, $spec ) = @_;

        my $directives = {
            required   => sub { 1 },
            min_length => sub { 1 },
            max_length => sub { 1 },
            data_type  => sub { 1 },
            ref_type   => sub { 1 },
            regex      => sub { 1 },
            filter  => sub { 1 },
            filters => sub { 1 },
            element => sub { 1 },

        };

        foreach ( keys %{$spec} ) {
            if ( !defined $directives->{$_} ) {
                die "The `$_` directive supplied by the `$mixin` mixin is not supported";
            }
            if ( !$directives->{$_}->() ) {
                die "The `$_` directive supplied by the `$mixin` mixin is invalid";
            }
        }

        return 1;
    }

    sub Oogly::check_field {
        my ( $self, $field, $spec ) = @_;

        my $directives = {

            mixin       => sub { 1 },
            mixin_field => sub { 1 },
            validation  => sub { 1 },
            errors      => sub { 1 },
            label       => sub { 1 },
            error       => sub { 1 },
            value       => sub { 1 },
            name        => sub { 1 },
            filter      => sub { 1 },
            filters     => sub { 1 },
            required    => sub { 1 },
            min_length  => sub { 1 },
            max_length  => sub { 1 },
            data_type   => sub { 1 },
            ref_type    => sub { 1 },
            regex       => sub { 1 },
            element     => sub { 1 },

        };

        foreach ( keys %{$spec} ) {
            if ( !defined $directives->{$_} ) {
                die "The `$_` directive supplied by the `$field` field is not supported";
            }
            if ( !$directives->{$_}->() ) {
                die "The `$_` directive supplied by the `$field` field is invalid";
            }
        }

        return 1;
    }

}

# The temppath method concatenates a file with the template directory and
# returns an absolute path
sub temppath {
    my ( $self, $file ) = @_;
    return path( $self->{templates}->{directory}, $file );
}

# The dynamic Template::Stash::LIST_OPS has method adds a 'find-in-array'
# virtual list method for Template-Toolkit
$Template::Stash::LIST_OPS->{has} = sub {
    my ( $list, $value ) = @_;
    return ( grep /$value/, @$list ) ? 1 : 0;
};

1;

__END__
=pod

=head1 NAME

Dancer::Plugin::DataFu::Form - Dancer HTML Form renderer

=head1 VERSION

version 0.0121

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

