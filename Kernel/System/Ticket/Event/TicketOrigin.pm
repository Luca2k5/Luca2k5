package Kernel::System::Ticket::Event::TicketOrigin;

use strict;
use warnings;

our @ObjectDependencies = ( 'Kernel::System::DynamicField', 'Kernel::System::DynamicField::Backend', 'Kernel::System::Ticket', 'Kernel::System::Ticket::Article' );

sub new { my ( $Type, %Param ) = @_; return bless {}, $Type; }

sub Run {
    my ( $Self, %Param ) = @_;
    return if !$Param{Data}->{TicketID};
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => 'TicketOrigin' );
    return 1 if !$DynamicField->{ID};
    my $Backend = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $Current = $Backend->ValueGet( DynamicFieldConfig => $DynamicField, ObjectID => $Param{Data}->{TicketID} );
    return 1 if defined $Current && length $Current;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my @Articles = $ArticleObject->ArticleList( TicketID => $Param{Data}->{TicketID}, OnlyFirst => 1 );
    return 1 if !@Articles;
    my %Article = $ArticleObject->BackendForArticle( TicketID => $Param{Data}->{TicketID}, ArticleID => $Articles[0]->{ArticleID} )
        ->ArticleGet( TicketID => $Param{Data}->{TicketID}, ArticleID => $Articles[0]->{ArticleID} );
    my $Origin = $Self->OriginFromArticle( Article => \%Article );
    return $Backend->ValueSet( DynamicFieldConfig => $DynamicField, ObjectID => $Param{Data}->{TicketID}, Value => $Origin, UserID => 1 );
}

sub OriginFromArticle {
    my ( $Self, %Param ) = @_;
    my $Article = $Param{Article} || {};
    return 'Agent' if ( $Article->{SenderType} || '' ) eq 'agent';
    return 'CustomerPortal' if ( $Article->{SenderType} || '' ) eq 'customer' && ( $Article->{ChannelName} || '' ) =~ /\A(?:Internal|OTOBO)\z/i;
    return 'Unknown';
}

1;
