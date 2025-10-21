# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://otobo.io/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::Language::de_OTOBOExtendedTicketStats;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Perl Module: Kernel/System/Stats/Dynamic/OTRSStatsQueueRestingTime.pm
    $Self->{Translation}->{'Reporting Timeslot'} = 'Berichte-Zeitspanne';
    $Self->{Translation}->{'Ticket ID'} = 'Ticket-Nummer';
    $Self->{Translation}->{'Queue join time'} = 'Queue Eingangszeitpunkt';
    $Self->{Translation}->{'Queue left time'} = 'Queue Ausgangszeitpunkt';
    $Self->{Translation}->{'Resting time (seconds)'} = 'Verweildauer (Sekunden)';
    $Self->{Translation}->{'Resting time (HH:MM:SS)'} = 'Verweildauer (HH:MM:SS)';
    $Self->{Translation}->{'Resting time (Working hours, seconds)'} = 'Verweildauer (Arbeitszeit, Sekunden)';
    $Self->{Translation}->{'Resting time (Working hours, HH:MM:SS)'} = 'Verweildauer (Arbeitszeit, HH:MM:SS)';

    # Perl Module: Kernel/System/Stats/Static/OTRSStatsResponseStatistic.pm
    $Self->{Translation}->{'Start Day'} = 'Start-Tag';
    $Self->{Translation}->{'Start Month'} = 'Start-Monat';
    $Self->{Translation}->{'Start Year'} = 'Start-Jahr';
    $Self->{Translation}->{'End Day'} = 'End-Tag';
    $Self->{Translation}->{'End Month'} = 'End-Monat';
    $Self->{Translation}->{'End Year'} = 'End-Jahr';
    $Self->{Translation}->{'Queues: All'} = 'Queues: Alle';

    # SysConfig
    $Self->{Translation}->{'A modified ticket list statistic to display the working time per queue.'} =
        'Eine angepasste TicketList-Statistik, um die Arbeitszeit pro Queue anzuzeigen.';
    $Self->{Translation}->{'Module to generate statistics about ticket duration of stay in queues.'} =
        'Modul zum Erstellen von Statistiken über die Verweildauer von Tickets in Queues.';
    $Self->{Translation}->{'This setting defines a limit for query results on ticket history table for OTRSStatsQueueRestingTime stat.'} =
        'Diese Einstellung definiert eine Limitierung von Suchergebnissen der Ticket-Historie für die Statistik OTRSStatsQueueRestingTime.';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    );

}

1;
