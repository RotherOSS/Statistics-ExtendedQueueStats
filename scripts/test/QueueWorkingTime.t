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

use strict;
use strict;
use warnings;
use vars (qw($Self));
use utf8;

# Set up the test driver $Self when we are running as a standalone script.
use Kernel::System::UnitTest::MockTime qw(:all);
use Kernel::System::UnitTest::RegisterDriver;

use Kernel::System::VariableCheck qw(:all);

my $TimeStamp2Epoch = sub {
    my %Param = @_;

    my $TimeStamp      = $Param{TimeStamp};
    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $TimeStamp,
        },
    );

    return $DateTimeObject->ToEpoch() if $DateTimeObject;
    return;
};

my @Tests = (
    {
        Name    => 'The great test 1',
        Queue   => 'Misc',
        Date    => '2014-10-27 16:00:00',
        Actions => [
            {
                Queue => 'Raw',
                Date  => '2014-10-27 16:00:05',
            },
            {
                Queue => 'Postmaster',
                Date  => '2014-10-27 16:00:10',
            },
            {
                State => 'closed successful',
                Date  => '2014-10-27 16:00:11',
            },
        ],
        Result => {
            Raw        => '0 m',
            Misc       => '0 m',
            Postmaster => '0 m',
        },
    },
    {
        Name   => 'The great test 2',
        Queue  => 'Postmaster',
        Date   => '2014-10-28 00:57:23',
        Result => {
            Junk       => '4 h 47 m',
            Misc       => '8 h 3 m',
            Postmaster => '43 m',
            Raw        => '3 h 11 m',
        },
        Actions => [
            {
                State => 'closed successful',
                Date  => '2014-10-28 01:40:33',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 02:42:41',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 03:30:38',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 03:36:43',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 04:12:29',
            },
            {
                State => 'open',
                Date  => '2014-10-28 04:21:33',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 04:56:15',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 05:08:24',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-28 05:08:47',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 06:03:35',
            },
            {
                State => 'closed successful',
                Date  => '2014-10-28 07:20:23',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-28 08:25:06',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-28 09:06:55',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-28 09:40:57',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-28 10:27:19',
            },
            {
                State => 'open',
                Date  => '2014-10-28 11:28:24',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 12:47:01',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-28 13:14:48',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-28 14:32:35',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 15:21:53',
            },
            {
                State => 'closed successful',
                Date  => '2014-10-28 16:01:58',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 16:05:07',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 16:43:31',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 17:32:26',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-28 18:41:27',
            },
            {
                State => 'open',
                Date  => '2014-10-28 19:27:30',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-28 20:27:23',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-28 21:17:55',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-28 21:28:28',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-28 21:39:54',
            },
            {
                State => 'closed successful',
                Date  => '2014-10-28 22:16:59',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-28 22:42:08',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-28 23:19:31',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-29 00:18:24',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-29 00:43:34',
            },
            {
                State => 'open',
                Date  => '2014-10-29 01:30:40',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-29 02:25:57',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-29 02:47:27',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-29 04:06:46',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-29 05:15:52',
            },
            {
                State => 'closed successful',
                Date  => '2014-10-29 05:16:22',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-29 06:18:31',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-29 06:58:29',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-29 08:15:36',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-29 08:56:49',
            },
            {
                State => 'open',
                Date  => '2014-10-29 09:23:58',
            },
            {
                Queue => 'Misc',
                Date  => '2014-10-29 09:54:24',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-29 09:59:18',
            },
            {
                Queue => 'Junk',
                Date  => '2014-10-29 10:13:50',
            },
            {
                Queue => 'Raw',
                Date  => '2014-10-29 11:19:18',
            },
        ],
    },
    {
        Name   => 'The great test 3',
        Queue  => 'Postmaster',
        Date   => '2014-11-01 09:26:55',
        Result => {
            Junk       => '5 h 3 m',
            Misc       => '3 h 41 m',
            Postmaster => '34 m',
            Raw        => '8 h 12 m',
        },
        Actions => [
            {
                State => 'closed successful',
                Date  => '2014-11-01 10:01:39',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-01 11:23:05',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-01 12:11:58',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-01 12:49:23',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-01 13:45:39',
            },
            {
                State => 'open',
                Date  => '2014-11-01 14:01:30',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-01 14:19:01',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-01 15:32:15',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-01 16:03:04',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-01 16:43:26',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-01 17:23:09',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-01 17:48:51',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-01 19:10:18',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-01 19:23:24',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-01 20:01:48',
            },
            {
                State => 'open',
                Date  => '2014-11-01 20:20:36',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-01 21:17:49',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-01 21:22:03',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-01 22:00:44',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-01 23:18:35',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-01 23:41:08',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-02 00:25:00',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-02 00:40:30',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-02 00:41:06',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-02 00:47:43',
            },
            {
                State => 'open',
                Date  => '2014-11-02 01:23:09',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-02 02:15:09',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-02 02:58:34',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 03:47:10',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-02 04:48:42',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-02 04:55:08',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 05:19:13',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 06:17:42',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 07:10:24',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-02 08:27:43',
            },
            {
                State => 'open',
                Date  => '2014-11-02 08:36:14',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-02 09:03:04',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-02 09:27:59',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-02 09:45:23',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 10:51:22',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-02 12:07:10',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-02 12:42:15',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 13:09:27',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 14:01:08',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-02 15:10:13',
            },
            {
                State => 'open',
                Date  => '2014-11-02 15:21:03',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 16:27:12',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 17:26:50',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 18:17:25',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-02 18:33:24',
            },
        ],
    },
    {
        Name   => 'The great test 4',
        Queue  => 'Postmaster',
        Date   => '2014-11-05 17:19:51',
        Result => {
            Junk       => '1 h 4 m',
            Misc       => '8 h 37 m',
            Postmaster => '11 m',
            Raw        => '6 h 39 m',
        },
        Actions => [
            {
                State => 'closed successful',
                Date  => '2014-11-05 17:31:05',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-05 18:27:56',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-05 19:43:50',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-05 19:56:11',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-05 19:56:37',
            },
            {
                State => 'open',
                Date  => '2014-11-05 21:12:49',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-05 22:14:48',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-05 22:30:11',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-05 23:47:08',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 00:06:00',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-06 00:58:43',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-06 02:03:18',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 03:23:20',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 04:07:20',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-06 04:35:28',
            },
            {
                State => 'open',
                Date  => '2014-11-06 05:32:16',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 05:46:28',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-06 06:50:08',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 07:24:28',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 07:53:16',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-06 08:29:41',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 09:15:56',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-06 10:38:29',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 10:39:17',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-06 11:34:15',
            },
            {
                State => 'open',
                Date  => '2014-11-06 12:09:17',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 12:24:50',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 13:47:49',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-06 13:56:34',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-06 14:09:46',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-06 14:28:57',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-06 15:11:47',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-06 16:01:34',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-06 16:47:29',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-06 17:17:52',
            },
            {
                State => 'open',
                Date  => '2014-11-06 18:39:53',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-06 19:56:08',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-06 21:13:46',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-06 22:23:45',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-06 22:50:02',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-06 22:52:35',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-06 23:36:07',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-07 00:53:00',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-07 01:00:15',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-07 01:19:52',
            },
            {
                State => 'open',
                Date  => '2014-11-07 01:32:44',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-07 02:34:51',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-07 03:28:48',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-07 04:25:58',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-07 04:38:02',
            },
        ],
    },
    {
        Name   => 'The great test 5',
        Queue  => 'Postmaster',
        Date   => '2014-11-11 22:13:14',
        Result => {
            Junk       => '4 h 4 m',
            Misc       => '5 h 46 m',
            Postmaster => '14 m',
            Raw        => '6 h 22 m',
        },
        Actions => [
            {
                State => 'closed successful',
                Date  => '2014-11-11 22:27:42',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-11 23:25:59',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-12 00:41:59',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 01:48:17',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 02:00:16',
            },
            {
                State => 'open',
                Date  => '2014-11-12 03:12:24',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-12 03:24:16',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-12 04:12:55',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-12 05:27:36',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 06:49:26',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-12 08:10:40',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 09:27:16',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 09:59:46',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 10:44:43',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 11:58:04',
            },
            {
                State => 'open',
                Date  => '2014-11-12 12:43:33',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-12 13:24:04',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 14:21:27',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 14:28:27',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-12 14:51:36',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-12 14:51:57',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 15:28:03',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-12 16:47:09',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-12 17:21:11',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-12 17:51:30',
            },
            {
                State => 'open',
                Date  => '2014-11-12 18:03:30',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 19:07:37',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-12 19:15:20',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-12 20:14:53',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-12 21:19:23',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-12 21:42:33',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-12 23:03:01',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-12 23:17:20',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-12 23:34:05',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-13 00:43:51',
            },
            {
                State => 'open',
                Date  => '2014-11-13 01:16:31',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-13 01:42:41',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-13 02:02:15',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-13 02:48:36',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-13 03:23:02',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-13 04:11:36',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-13 04:48:53',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-13 05:51:20',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-13 06:55:02',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-13 07:40:06',
            },
            {
                State => 'open',
                Date  => '2014-11-13 07:47:57',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-13 09:01:08',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-13 09:38:13',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-13 09:51:49',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-13 10:21:25',
            },
        ],
    },
    {
        Name   => 'The great test 6',
        Queue  => 'Postmaster',
        Date   => '2014-11-18 12:19:21',
        Result => {
            Junk       => '7 h 43 m',
            Misc       => '5 h 57 m',
            Postmaster => '25 m',
            Raw        => '5 h 56 m',
        },
        Actions => [
            {
                State => 'closed successful',
                Date  => '2014-11-18 12:44:51',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-18 13:53:41',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-18 14:32:01',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-18 15:43:56',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-18 17:07:12',
            },
            {
                State => 'open',
                Date  => '2014-11-18 17:30:30',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-18 18:52:02',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-18 19:15:40',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-18 20:13:15',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-18 20:56:31',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-18 22:15:34',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-18 23:05:46',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-18 23:43:53',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-18 23:57:33',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 00:48:31',
            },
            {
                State => 'open',
                Date  => '2014-11-19 01:44:29',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-19 02:19:17',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-19 03:33:05',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 04:25:45',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-19 05:20:24',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-19 05:56:12',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-19 06:14:33',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-19 06:31:29',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-19 07:12:50',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 07:22:22',
            },
            {
                State => 'open',
                Date  => '2014-11-19 08:07:10',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 09:20:43',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 10:08:28',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 11:18:57',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 11:41:07',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-19 12:12:59',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-19 12:26:27',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-19 13:18:17',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-19 13:28:20',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-19 14:42:19',
            },
            {
                State => 'open',
                Date  => '2014-11-19 15:51:19',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 16:31:45',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-19 16:56:29',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 17:59:06',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-19 18:06:04',
            },
            {
                State => 'closed successful',
                Date  => '2014-11-19 19:24:53',
            },
            {
                Queue => 'Raw',
                Date  => '2014-11-19 20:11:16',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 20:27:02',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-19 20:37:50',
            },
            {
                Queue => 'Junk',
                Date  => '2014-11-19 21:58:10',
            },
            {
                State => 'open',
                Date  => '2014-11-19 22:08:59',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-19 23:02:30',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-19 23:24:17',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-20 00:43:22',
            },
            {
                Queue => 'Misc',
                Date  => '2014-11-20 01:10:50',
            },
        ],
    },
);

# create local objects
my $QueueObject                      = $Kernel::OM->Get('Kernel::System::Queue');
my $StateObject                      = $Kernel::OM->Get('Kernel::System::State');
my $TicketObject                     = $Kernel::OM->Get('Kernel::System::Ticket');
my $HelperObject                     = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $OTOBOStatsQueueWorkingTimeObject = $Kernel::OM->Get('Kernel::System::Stats::Dynamic::OTOBOStatsQueueWorkingTime');

for my $Test (@Tests) {
    FixedTimeSet(
        $TimeStamp2Epoch->( TimeStamp => $Test->{Date} ),
    );

    my $TicketID = $TicketObject->TicketCreate(
        Title        => 'Some Ticket_Title',
        Queue        => $Test->{Queue},
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerNo   => '123465',
        CustomerUser => 'customer@example.com',
        OwnerID      => 1,
        UserID       => 1,
    );

    $Self->True(
        $TicketID,
        $Test->{Name} . ' - Create ticket',
    );

    for my $Action ( @{ $Test->{Actions} } ) {
        FixedTimeSet(
            $TimeStamp2Epoch->( TimeStamp => $Action->{Date} ),
        );

        if ( $Action->{Queue} ) {
            my $Success = $TicketObject->TicketQueueSet(
                Queue    => $Action->{Queue},
                TicketID => $TicketID,
                UserID   => 1,
            );

            $Self->True(
                $Success,
                $Test->{Name} . ' - Ticket move to queue \'' . $Action->{Queue} . '\'',
            );
        }
        elsif ( $Action->{State} ) {
            my $StateID = $StateObject->StateLookup(
                State => $Action->{State},
            );

            $Self->True(
                $StateID,
                $Test->{Name} . ' - Lookup state \'' . $Action->{State} . '\'',
            );

            my $Success = $TicketObject->TicketStateSet(
                StateID  => $StateID,
                TicketID => $TicketID,
                UserID   => 1,
            );

            $Self->True(
                $Success,
                $Test->{Name} . ' - Ticket change state to \'' . $Action->{State} . '\'',
            );
        }
    }

    my %Ticket = $TicketObject->TicketGet(
        TicketID => $TicketID,
        UserID   => 1,
    );

    $OTOBOStatsQueueWorkingTimeObject->_ModifyTicketQueueTimes(
        Ticket => \%Ticket,
    );

    for my $Queue ( sort keys %{ $Test->{Result} } ) {
        my $QueueID = $QueueObject->QueueLookup( Queue => $Queue );

        my $ExpectedValue = $Test->{Result}->{$Queue};
        my $ResultValue   = $Ticket{ 'Queue_' . $QueueID . '_Time' };

        $Self->Is(
            $ResultValue,
            $ExpectedValue,
            $Test->{Name} . ' - Check result value for queue \'' . $Queue . '\'',
        );
    }

    my $Delete = $TicketObject->TicketDelete(
        TicketID => $TicketID,
        UserID   => 1,
    );
    $Self->True(
        $Delete,
        $Test->{Name} . ' - Delete ticket id \'' . $TicketID . '\'',
    );
}
continue {
    FixedTimeUnset();
}

$Self->DoneTesting();
