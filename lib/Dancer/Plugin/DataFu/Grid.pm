# ABSTRACT: Dancer HTML Grid/Table renderer
package Dancer::Plugin::DataFu::Grid;
BEGIN {
  $Dancer::Plugin::DataFu::Grid::VERSION = '0.0111';
}

use warnings;
use 5.008001;
use Template;
use Template::Stash;
use Array::Unique;
use Dancer::FileUtils;
use Hash::Merge qw/merge/;
use Oogly qw/:all !error/;
use Dancer qw/:syntax !error/;
use File::ShareDir qw/:ALL/;

{
    no warnings 'redefine';
    sub new {
        my $class    = shift;
        my $settings = shift;
        my $profiles = $settings->{grid}->{profiles}
          || die 'No grid profiles are configured in the config file';
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
    
        #my $globule = {};
        #my $params  = params;
        #foreach my $key ( keys %{$fields} ) {
        #    foreach my $field ( keys %{ $fields->{$key} } ) {
        #        $globule->{"$key.$field"} = $fields->{$key}->{$field};
        #    }
        #}
        
        $self->{profile} = $fields;
    
        my $template_directory =
          $settings->{grid}->{templates}
          ? path( config->{appdir}, $settings->{grid}->{templates} )
          : module_dir('Dancer::Plugin::DataFu') . "/elements/";
    
        $self->{profiles}  = \@profiles;
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
    
    sub template {
        my ( $self, $element, $path ) = @_;
        return $self->{data}->{templates}->{$element} = $path;
    }
}

sub render {
    my ( $self, $name, $dataset, $profile, @options ) = @_;
    my $configuration = {};
       $profile = $self->{profile}->{$profile} if $profile;;
    
    # check for grid template vars
    if ( ref( $options[@options] ) eq "HASH" ) {
        $configuration = pop @options;
    }

    my $tempro = sub {
        my ($file, $args) = @_;
        my $template    = Template->new(
            INTERPOLATE => 1,
            EVAL_PERL   => 1,
            ABSOLUTE    => 1,
            ANYCASE     => 1
        );
        
        my $data = undef;
        
        $template->process( $file, $args, \$data ) || die $template->error;
        
        return $data;
    };

    my $counter    = 0;
    my @grid_table = ();
    my @grid_parts = ();
    my $tvars      = {
        col     => undef,
        row     => undef,
        grid    => $self,
        name    => $name,
        prof    => $profile,
        vars    => $configuration,
        data    => $dataset,
        content => undef
    };
    
    # column headers
    for (my $i = 0; $i < @{$profile->{columns}}; $i++){
        $tvars->{col} = $profile->{columns}->[$i];
        $grid_parts[$counter++] = $tempro->($self->temppath('thead.tt'), $tvars);
    }
    
    $tvars->{content} = join( "\n", @grid_parts );
    push @grid_table, $tempro->($self->temppath('trow.tt'), $tvars);
    
    @grid_parts = ();
    $counter = 0;
    
    # data rows
    foreach my $row (@{$dataset}) {
        
        for (my $i = 0; $i < @{$profile->{columns}}; $i++) {
            
            # use dataset value if bindto exists
            $profile->{columns}->[$i]->{data}
                =  $row->{$profile->{columns}->[$i]->{bindto}}
                if defined $profile->{columns}->[$i]->{bindto};
                
            $tvars->{row} = $row;
            $tvars->{col} = $profile->{columns}->[$i];
            $grid_parts[$counter++] = $tempro->($self->temppath('tdata.tt'), $tvars);
            
        }
        
        $tvars->{content} = join( "\n", @grid_parts );
        push @grid_table, $tempro->($self->temppath('trow.tt'), $tvars);
        
        @grid_parts = ();
        $counter = 0;
        
    }
    
    # table header
    if (defined $profile->{header}) {
        $tvars->{col} = $profile->{columns};
        $tvars->{header} = $tempro->($self->temppath('trow.tt'),
            { content => $tempro->($self->temppath('theader.tt'), $tvars) }
        );
    }
    
    # footer
    if (defined $profile->{navigation}) {
        $tvars->{col} = $profile->{columns};
        $tvars->{navigation} = $tempro->($self->temppath('trow.tt'),
            { content => $tempro->($self->temppath('tnavigation.tt'), $tvars) }
        );
    }
    
    # output table
    $tvars->{rows} = join( "\n", @grid_table );
    return $tempro->($self->temppath('table.tt'), $tvars);
}

sub templates {
    my ( $self, $path ) = @_;
    return $self->{data}->{templates}->{directory} = $path;
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

Dancer::Plugin::DataFu::Grid - Dancer HTML Grid/Table renderer

=head1 VERSION

version 0.0111

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

