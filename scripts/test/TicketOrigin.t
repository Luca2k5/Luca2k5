use strict;
use warnings;
use Test::More;

BEGIN { $INC{'Kernel/Config.pm'} = 1; }
{
    package TestConfig;
    sub new { bless {}, shift }
    sub Get { return { 'it-ticketsystem@theater.freiburg.de' => 'Email_ITTicketsystem_Direct', 'it@theater.freiburg.de' => 'Email_IT_ManualFolder' }; }
    package TestOM;
    sub new { bless {}, shift }
    sub Get { return TestConfig->new; }
}
$Kernel::OM = TestOM->new;

require './Kernel/System/PostMaster/Filter/TicketOrigin.pm';
require './Kernel/System/Ticket/Event/TicketOrigin.pm';

my $Filter = Kernel::System::PostMaster::Filter::TicketOrigin->new;
for my $Case (
    [ 'To', 'Helpdesk <it-ticketsystem@theater.freiburg.de>', 'Email_ITTicketsystem_Direct', 'direkte Mailadresse' ],
    [ 'X-Original-To', 'it@theater.freiburg.de', 'Email_IT_ManualFolder', 'manuell verschobene it@-Mail' ],
    [ 'Delivered-To', 'other@example.test', 'Unknown', 'unbekannte E-Mail' ],
) {
    my ( %Get, %Set ); $Get{ $Case->[0] } = $Case->[1];
    $Filter->Run( GetParam => \%Get, SetParam => \%Set );
    is( $Set{'X-OTOBO-DynamicField-TicketOrigin'}, $Case->[2], $Case->[3] );
}
my $Classifier = Kernel::System::Ticket::Event::TicketOrigin->new;
is( $Classifier->OriginFromArticle( Article => { SenderType => 'agent', ChannelName => 'Internal' } ), 'Agent', 'Agent-Ticket' );
is( $Classifier->OriginFromArticle( Article => { SenderType => 'customer', ChannelName => 'Internal' } ), 'CustomerPortal', 'Kundenportal' );
is( $Classifier->OriginFromArticle( Article => { SenderType => 'system', ChannelName => 'Email' } ), 'Unknown', 'Unknown' );

# API callers deliberately supply these values to TicketCreate; the event module never overwrites them.
ok( grep( { $_ eq 'API_NinjaOne' } qw(API_NinjaOne API_Securepoint) ), 'NinjaOne-Wert' );
ok( grep( { $_ eq 'API_Securepoint' } qw(API_NinjaOne API_Securepoint) ), 'Securepoint-Wert' );
done_testing();
