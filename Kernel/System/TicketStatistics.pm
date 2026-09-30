package Kernel::System::TicketStatistics;

use strict;
use warnings;
use Kernel::System::VariableCheck qw(IsArrayRefWithData);

our @ObjectDependencies = ( 'Kernel::Config', 'Kernel::System::DateTime', 'Kernel::System::Ticket' );

sub new { my ( $Type, %Param ) = @_; return bless {}, $Type; }

sub Build {
    my ( $Self, %Param ) = @_;
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $OriginConfig = $ConfigObject->Get('TicketStatistics::Origins') || {};
    my @Origins = IsArrayRefWithData( $Param{Origins} ) ? grep { exists $OriginConfig->{$_} } @{ $Param{Origins} } : sort keys %{$OriginConfig};
    @Origins = sort keys %{$OriginConfig} if !@Origins;

    my ( $From, $To, $Aggregation ) = $Self->_Range( DateTimeObject => $DateTimeObject, %Param );
    my @Buckets = $Self->_Buckets( From => $From, To => $To, Aggregation => $Aggregation );
    my %Total = ( Created => 0, Closed => 0 );
    my @Rows;
    my @CreatedSeries = (0) x scalar @Buckets;
    my @ClosedSeries = (0) x scalar @Buckets;
    my %SourceSeries;

    for my $Origin (@Origins) {
        my ( $Created, $Closed ) = ( 0, 0 );
        for my $Index ( 0 .. $#Buckets ) {
            my $Bucket = $Buckets[$Index];
            my $C = $Self->_Count( Origin => $Origin, TicketCreateTimeNewerDate => $Bucket->{From}, TicketCreateTimeOlderDate => $Bucket->{To} );
            my $D = $Self->_Count( Origin => $Origin, TicketCloseTimeNewerDate  => $Bucket->{From}, TicketCloseTimeOlderDate  => $Bucket->{To} );
            $Created += $C; $Closed += $D; $CreatedSeries[$Index] += $C; $ClosedSeries[$Index] += $D;
            push @{ $SourceSeries{$Origin}->{Created} }, $C;
            push @{ $SourceSeries{$Origin}->{Closed} }, $D;
        }
        $Total{Created} += $Created; $Total{Closed} += $Closed;
        push @Rows, { Origin => $Origin, Label => $OriginConfig->{$Origin}, Created => $Created, Closed => $Closed, Difference => $Created - $Closed };
    }
    for my $Row (@Rows) { $Row->{Share} = $Total{Created} ? sprintf( '%.1f', 100 * $Row->{Created} / $Total{Created} ) : '0.0'; }
    my $Open = 0;
    $Open += $Self->_Count( Origin => $_, StateType => [ 'new', 'open', 'pending reminder', 'pending auto' ] ) for @Origins;
    return {
        From => $From, To => $To, Aggregation => $Aggregation, Created => $Total{Created}, Closed => $Total{Closed},
        Difference => $Total{Created} - $Total{Closed}, Open => $Open, OriginRows => \@Rows, Origins => \@Origins,
        Chart => { Labels => [ map { $_->{Label} } @Buckets ], Created => \@CreatedSeries, Closed => \@ClosedSeries, Sources => \%SourceSeries },
    };
}

sub _Count {
    my ( $Self, %Param ) = @_;
    my $Origin = delete $Param{Origin};
    my $IDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        Result => 'ARRAY', Limit => 100_000, UserID => 1, Permission => 'ro',
        DynamicField_TicketOrigin => { Equals => $Origin }, %Param,
    ) || [];
    return scalar @{$IDs};
}

sub _Range {
    my ( $Self, %Param ) = @_;
    my $Preset = $Param{Preset} || '30';
    my $Aggregation = $Param{Aggregation} || ( $Preset eq '365' ? 'month' : 'day' );
    $Aggregation = 'day' if $Aggregation !~ /\A(?:day|week|month)\z/;
    my $Now = $Param{DateTimeObject};
    my $To = $Param{To} && $Param{To} =~ /\A\d{4}-\d{2}-\d{2}\z/ ? "$Param{To} 23:59:59" : $Now->ToString();
    my $From;
    if ( $Preset eq 'custom' && $Param{From} && $Param{From} =~ /\A\d{4}-\d{2}-\d{2}\z/ ) { $From = "$Param{From} 00:00:00"; }
    else {
        my $Days = $Preset =~ /\A(?:7|14|30|365)\z/ ? $Preset : 30;
        my $Start = $Kernel::OM->Create( 'Kernel::System::DateTime', ObjectParams => { String => $To } );
        $Start->Subtract( Days => $Days - 1 );
        $From = substr( $Start->ToString(), 0, 10 ) . ' 00:00:00';
    }
    return ( $From, $To, $Aggregation );
}

sub _Buckets {
    my ( $Self, %Param ) = @_;
    my @Result;
    my $Cursor = $Kernel::OM->Create( 'Kernel::System::DateTime', ObjectParams => { String => $Param{From} } );
    while ( $Cursor->ToString() le $Param{To} ) {
        my $From = $Cursor->ToString();
        my $Next = $Cursor->Clone();
        $Next->Add( $Param{Aggregation} eq 'month' ? ( Months => 1 ) : $Param{Aggregation} eq 'week' ? ( Days => 7 ) : ( Days => 1 ) );
        my $ToObject = $Next->Clone(); $ToObject->Subtract( Seconds => 1 );
        my $To = $ToObject->ToString() lt $Param{To} ? $ToObject->ToString() : $Param{To};
        push @Result, { From => $From, To => $To, Label => substr( $From, 0, 10 ) };
        $Cursor = $Next;
    }
    return @Result;
}

1;
