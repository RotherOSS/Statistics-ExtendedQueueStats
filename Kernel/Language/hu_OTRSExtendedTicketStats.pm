# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Language::hu_OTRSExtendedTicketStats;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Perl Module: Kernel/System/Stats/Dynamic/OTRSStatsQueueRestingTime.pm
    $Self->{Translation}->{'Reporting Timeslot'} = 'Jelentéskészítés időrése';
    $Self->{Translation}->{'Ticket ID'} = 'Jegyazonosító';
    $Self->{Translation}->{'Queue join time'} = 'Várólista-belépési idő';
    $Self->{Translation}->{'Queue left time'} = 'Várólista-elhagyási idő';
    $Self->{Translation}->{'Resting time (seconds)'} = 'Pihenési idő (másodperc)';
    $Self->{Translation}->{'Resting time (HH:MM:SS)'} = 'Pihenési idő (ÓÓ:PP:MM)';
    $Self->{Translation}->{'Resting time (Working hours, seconds)'} = 'Pihenési idő (munkaidő, másodperc)';
    $Self->{Translation}->{'Resting time (Working hours, HH:MM:SS)'} = 'Pihenési idő (munkaidő, ÓÓ:PP:MM)';

    # Perl Module: Kernel/System/Stats/Static/OTRSStatsResponseStatistic.pm
    $Self->{Translation}->{'Start Day'} = 'Kezdés napja';
    $Self->{Translation}->{'Start Month'} = 'Kezdés hónapja';
    $Self->{Translation}->{'Start Year'} = 'Kezdés éve';
    $Self->{Translation}->{'End Day'} = 'Befejezés napja';
    $Self->{Translation}->{'End Month'} = 'Befejezés hónapja';
    $Self->{Translation}->{'End Year'} = 'Befejezés éve';
    $Self->{Translation}->{'Queues: All'} = 'Várólisták: összes';

    # SysConfig
    $Self->{Translation}->{'A modified ticket list statistic to display the working time per queue.'} =
        'Egy módosított jegylista statisztika a várólistánkénti munkaidő megjelenítéséhez.';
    $Self->{Translation}->{'Module to generate statistics about ticket duration of stay in queues.'} =
        'Egy modul statisztikák előállításához arról, hogy egy jegy mennyi időt töltött a várólistákban.';
    $Self->{Translation}->{'This setting defines a limit for query results on ticket history table for OTRSStatsQueueRestingTime stat.'} =
        'Ez a beállítás meghatározza a lekérdezési eredmények korlátját a jegyelőzmények táblánál a várólistákban eltöltött pihenési idő statisztikához.';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    );

}

1;
