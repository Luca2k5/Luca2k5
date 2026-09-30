use strict;
use warnings;
use Test::More;

sub in_range { my ( $value, $from, $to ) = @_; return $value ge $from && $value le $to; }
my $From = '2026-08-25 00:00:00'; my $To = '2026-09-05 23:59:59';
ok( in_range( '2026-09-01 12:00:00', $From, $To ), 'Zeitraum über Monatswechsel' );
my $Ticket = { Created => '2026-08-01 09:00:00', Closed => '2026-09-02 10:00:00', Origin => 'Agent' };
ok( !in_range( $Ticket->{Created}, $From, $To ) && in_range( $Ticket->{Closed}, $From, $To ), 'vor Zeitraum erstellt und im Zeitraum geschlossen' );
my %Selected = map { $_ => 1 } qw(Agent API_NinjaOne);
ok( $Selected{Agent} && $Selected{API_NinjaOne} && !$Selected{Unknown}, 'Filter mehrerer Quellen gleichzeitig' );
done_testing();
