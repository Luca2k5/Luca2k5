package Kernel::System::Console::Command::Maint::TicketOriginBackfill;

use strict;
use warnings;
use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = ( 'Kernel::System::DynamicField', 'Kernel::System::DynamicField::Backend', 'Kernel::System::Ticket' );

sub Configure {
    my ($Self) = @_;
    $Self->Description('Preview or apply TicketOrigin classification for historical tickets.');
    $Self->AddOption( Name => 'dry-run', Description => 'Print proposed changes and change nothing.', Required => 0, HasValue => 0 );
    $Self->AddOption( Name => 'apply', Description => 'Explicitly write proposed values.', Required => 0, HasValue => 0 );
    return;
}

sub Run {
    my ($Self) = @_;
    my $Apply = $Self->GetOption('apply');
    if ( !$Apply && !$Self->GetOption('dry-run') ) { $Self->PrintError('Specify --dry-run or --apply.'); return $Self->ExitCodeError(); }
    if ( $Apply && $Self->GetOption('dry-run') ) { $Self->PrintError('--dry-run and --apply are mutually exclusive.'); return $Self->ExitCodeError(); }
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $Field = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => 'TicketOrigin' );
    return $Self->ExitCodeError() if !$Field->{ID};
    my $Backend = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $IDs = $TicketObject->TicketSearch( Result => 'ARRAY', Limit => 1_000_000, UserID => 1, Permission => 'ro' ) || [];
    for my $TicketID ( @{$IDs} ) {
        next if $Backend->ValueGet( DynamicFieldConfig => $Field, ObjectID => $TicketID );
        my %Ticket = $TicketObject->TicketGet( TicketID => $TicketID, DynamicFields => 0, UserID => 1, Silent => 1 );
        my ( $Origin, $Reason ) = $Self->_Detect( TicketID => $TicketID );
        $Self->Print("$TicketID / $Ticket{TicketNumber} / $Origin / $Reason\n");
        $Backend->ValueSet( DynamicFieldConfig => $Field, ObjectID => $TicketID, Value => $Origin, UserID => 1 ) if $Apply;
    }
    return $Self->ExitCodeOk();
}

sub _Detect {
    my ( $Self, %Param ) = @_;
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my @List = $ArticleObject->ArticleList( TicketID => $Param{TicketID}, OnlyFirst => 1 );
    return ( 'Unknown', 'kein erster Artikel vorhanden' ) if !@List;
    my %Article = $ArticleObject->BackendForArticle( TicketID => $Param{TicketID}, ArticleID => $List[0]->{ArticleID} )
        ->ArticleGet( TicketID => $Param{TicketID}, ArticleID => $List[0]->{ArticleID} );
    my $Classifier = $Kernel::OM->Create('Kernel::System::Ticket::Event::TicketOrigin');
    my $Origin = $Classifier->OriginFromArticle( Article => \%Article );
    my $Reason = $Origin eq 'Agent' ? 'erster Artikel hat SenderType agent'
        : $Origin eq 'CustomerPortal' ? 'erster Artikel ist customer über internen OTOBO-Kanal'
        : 'historisch nicht eindeutig erkennbar; E-Mail-Empfängerheader nicht dauerhaft garantiert';
    return ( $Origin, $Reason );
}

1;
