package Kernel::System::PostMaster::Filter::TicketOrigin;

use strict;
use warnings;

our @ObjectDependencies = ('Kernel::Config');

sub new { my ( $Type, %Param ) = @_; return bless {}, $Type; }

sub Run {
    my ( $Self, %Param ) = @_;
    return 1 if !$Param{GetParam} || !$Param{SetParam};
    return 1 if $Param{GetParam}->{'X-OTOBO-DynamicField-TicketOrigin'};
    my $Map = $Kernel::OM->Get('Kernel::Config')->Get('TicketStatistics::RecipientMap') || {};
    my @HeaderNames = qw(To Delivered-To Envelope-To X-Original-To X-Envelope-To Apparently-To);
    my $Headers = join ' ', map { $Param{GetParam}->{$_} // $Param{GetParam}->{lc $_} // '' } @HeaderNames;
    for my $Address ( sort keys %{$Map} ) {
        if ( $Headers =~ /(?:\A|[^A-Z0-9_.+\-])\Q$Address\E(?:\z|[^A-Z0-9_.+\-])/i ) {
            $Param{SetParam}->{'X-OTOBO-DynamicField-TicketOrigin'} = $Map->{$Address};
            return 1;
        }
    }
    $Param{SetParam}->{'X-OTOBO-DynamicField-TicketOrigin'} = 'Unknown';
    return 1;
}

1;
