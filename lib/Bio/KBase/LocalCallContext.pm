package Bio::KBase::LocalCallContext;

use strict;
use warnings;
use feature qw( say );

sub new {
    my ( $class, $token, $user, $provenance, $method ) = @_;
    my $self = {
        token      => $token,
        user_id    => $user,
        provenance => $provenance,
        method     => $method,
    };
    return bless $self, $class;
}

sub user_id {
    my ( $self ) = @_;
    return $self->{ user_id };
}

sub token {
    my ( $self ) = @_;
    return $self->{ token };
}

sub provenance {
    my ( $self ) = @_;
    return $self->{ provenance };
}

sub method {
    my ( $self ) = @_;
    return $self->{ method };
}

sub authenticated {
    return 1;
}

sub log_info {
    shift->_say_msg( @_ );
}

sub log_info {
    shift->_say_msg( @_ );
}

sub _say_msg {
    my ( $self, $msg ) = @_;
    say STDERR $msg;
}

sub TO_JSON {
    my ( $self ) = @_;

    return {
        map { $_ => $self->$_ } qw( authenticated method provenance token user_id )
    };
}

1;

