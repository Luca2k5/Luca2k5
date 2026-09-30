package Kernel::Modules::AgentTicketStatistics;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;
    my $Self = {%Param};
    bless $Self, $Type;
    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $StatisticsObject = $Kernel::OM->Get('Kernel::System::TicketStatistics');

    my @Origins = $ParamObject->GetArray( Param => 'Origin' );
    my %Request = map { $_ => scalar $ParamObject->GetParam( Param => $_ ) } qw(Preset From To Aggregation);
    $Request{Origins} = \@Origins;
    my $Result = $StatisticsObject->Build(%Request);

    for my $Origin ( @{ $Result->{OriginRows} } ) {
        $LayoutObject->Block( Name => 'OriginRow', Data => $Origin );
    }
    my $JSON = $LayoutObject->JSONEncode( Data => $Result->{Chart} );
    return $LayoutObject->Header()
        . $LayoutObject->NavigationBar()
        . $LayoutObject->Output( TemplateFile => 'AgentTicketStatistics', Data => { %{$Result}, ChartJSON => $JSON } )
        . $LayoutObject->Footer();
}

1;
