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
use warnings;
use vars (qw($Self));
use utf8;

use Kernel::System::VariableCheck qw(:all);

# create local objects
my $UserID = 1;
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Stats' => {
        UserID => $UserID,
    },
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $StatsObject  = $Kernel::OM->Get('Kernel::System::Stats');

$Self->{UnitTestPrefix} = 'UnitTest-OTRSStatsQueueRestingTime';

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

my $Epoch2TimeStamp = sub {
    my %Param = @_;

    my $Epoch          = $Param{Epoch};
    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            Epoch => $Epoch,
        },
    );

    return $DateTimeObject->ToString() if $DateTimeObject;
    return;
};

# get state object
my $StateObject = $Kernel::OM->Get('Kernel::System::State');

# add stats
my $StatID = $StatsObject->StatsAdd( UserID => $UserID );
$Self->True(
    $StatID > 0,
    'Create Stat',
);

# get queue object
my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

# create test queues
my %Queues;
for my $Number ( 1 .. 3 ) {
    my $QueueID = $QueueObject->QueueAdd(
        Name            => $Self->{UnitTestPrefix} . $Number,
        ValidID         => 1,
        GroupID         => 1,
        SystemAddressID => 1,
        SalutationID    => 1,
        SignatureID     => 1,
        UserID          => $UserID,
    );
    $Self->True(
        $QueueID,
        'Create test queue ' . $Number,
    );
    $Queues{$Number} = $QueueID;
}

# determine test states
my %States;
my %AllStates = $StateObject->StateList(
    UserID => $UserID,
);
my %AllStatesReverse = reverse %AllStates;
for my $StateType ( 'open', 'pending reminder', 'closed', ) {
    my @StateList = $StateObject->StateGetStatesByType(
        StateType => [$StateType],
        Result    => 'Name',
    );

    # only allow valid states
    @StateList = grep { $AllStatesReverse{$_} } @StateList;
    $Self->True(
        $StateList[0],
        'Determine test state of type ' . $StateType,
    );
    $States{$StateType} = $StateList[0];
}

# define test start and stop times (to be used with relative times later)
my $StatsStartSystemTime = '631148400';
my $StatsStartTimeStamp  = '1989-12-31 23:00:00';
my $StatsStopSystemTime  = '631148500';
my $StatsStopTimeStamp   = '1989-12-31 23:01:40';

# set OTRSExtendedTicketStats and add restrictions
my $StatsRestrictions = {
    UseAsXvalue => [
        {
            Block          => 'MultiSelectField',
            Element        => 'TicketAttributes',
            Fixed          => 1,
            Name           => 'Attributes to be printed',
            Selected       => 1,
            SelectedValues => [
                'TicketID',
                'Created',
                'Changed',
                'Closed',
                'State',
                'Queue',
                'QueueJoinTime',
                'QueueLeftTime',
                'RestingTimeSeconds',
            ],
            Values => {
                TicketID           => 'TicketID',
                Created            => 'Created',
                Changed            => 'Changed',
                Closed             => 'Close Time',
                State              => 'State',
                Queue              => 'Queue',
                QueueJoinTime      => 'Queue join time',
                QueueLeftTime      => 'Queue left time',
                RestingTimeSeconds => 'Resting time (seconds)',
            },
        },
    ],
    UseAsValueSeries => [
        {
            Block          => 'SelectField',
            Element        => 'SortSequence',
            Fixed          => 1,
            Name           => 'Sort sequence',
            Selected       => 0,
            SelectedValues => [
                'Up',
            ],
            Values => {
                Up => 'ascending',
            },
        },
    ],
    UseAsRestriction => [
        {
            Block          => 'MultiSelectField',
            Element        => 'QueueIDs',
            Fixed          => 1,
            Name           => 'Queue',
            Selected       => 1,
            SelectedValues => [
                $Queues{1},
                $Queues{2},
            ],
            Values => {
                $Queues{1} => $Self->{UnitTestPrefix} . 1,
                $Queues{2} => $Self->{UnitTestPrefix} . 2,
            },
        },
        {
            Block     => 'Time',
            Element   => 'ReportingTimeslot',
            Fixed     => 1,
            Name      => 'Reporting Timeslot',
            Selected  => 1,
            TimeStart => $StatsStartTimeStamp,
            TimeStop  => $StatsStopTimeStamp,
            Values    => {
                TimeStart => 'ReportingTimeslotOlderDate',
                TimeStop  => 'ReportingTimeslotNewerDate',
            },
        },
    ],
};
my $Update = $StatsObject->StatsUpdate(
    StatID => $StatID,
    Hash   => {
        Title        => 'TestTitle from UnitTest.pl',
        Description  => 'some Description',
        Object       => 'Ticket',
        Format       => ['CSV'],
        ObjectModule => 'Kernel::System::Stats::Dynamic::OTRSStatsQueueRestingTime',
        Permission   => ['1'],
        StatType     => 'dynamic',
        Valid        => '1',
        %{$StatsRestrictions},
    },
    UserID => $UserID,
);
$Self->True(
    $Update,
    'Update Stat',
);

my $GetTestTicketDefinition = sub {

    # definition of tickets
    my $TestTickets = {
        'created within timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime + 5,                           # Created
                        $StatsStartSystemTime + 5,                           # Changed
                        '',                                                  # Closed
                        'open',                                              # State
                        1,                                                   # Queue
                        $StatsStartSystemTime + 5,                           # QueueJoinTime
                        '',                                                  # QueueLeftTime
                        $StatsStopSystemTime - $StatsStartSystemTime - 5,    # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 5,
                },
            ],
        },
        'created before timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime - 5,                           # Created
                        $StatsStartSystemTime - 5,                           # Changed
                        '',                                                  # Closed
                        'open',                                              # State
                        1,                                                   # Queue
                        $StatsStartSystemTime - 5,                           # QueueJoinTime
                        '',                                                  # QueueLeftTime
                        $StatsStopSystemTime - $StatsStartSystemTime + 5,    # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime - 5,
                },
            ],
        },
        'created after timeframe' => {
            ExpectedResult => {
                Listed => 0,    # 1 or 0
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                   # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                             # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                        # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 105,
                },
            ],
        },
        'created within timeframe, non-reported queue' => {
            ExpectedResult => {
                Listed => 0,    # 1 or 0
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                   # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 3,                             # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                        # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 105,
                },
            ],
        },
        'created within timeframe, closed instantly' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime + 5,    # Created
                        $StatsStartSystemTime + 5,    # Changed
                        $StatsStartSystemTime + 5,    # Closed
                        'closed',                     # State
                        1,                            # Queue
                        $StatsStartSystemTime + 5,    # QueueJoinTime
                        $StatsStartSystemTime + 5,    # QueueLeftTime
                        0,                            # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'closed',                    # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 5,
                },
            ],
        },
        'created before and closed within timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime - 5,     # Created
                        $StatsStartSystemTime + 55,    # Changed
                        $StatsStartSystemTime + 55,    # Closed
                        'closed',                      # State
                        1,                             # Queue
                        $StatsStartSystemTime - 5,     # QueueJoinTime
                        $StatsStartSystemTime + 55,    # QueueLeftTime
                        60,                            # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime - 5,
                },
                {
                    Action    => 'StateUpdate',                # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    State     => 'closed',                     # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 55,
                },
            ],
        },
        'created and closed before timeframe' => {
            ExpectedResult => {
                Listed => 0,    # 1 or 0
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime - 5,
                },
                {
                    Action    => 'StateUpdate',               # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    State     => 'closed',                    # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime - 1,
                },
            ],
        },
        'created before and closed after timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime - 5,      # Created
                        $StatsStartSystemTime + 105,    # Changed
                        $StatsStartSystemTime + 105,    # Closed
                        'closed',                       # State
                        1,                              # Queue
                        $StatsStartSystemTime - 5,      # QueueJoinTime
                        '',                             # QueueLeftTime
                        105,                            # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime - 5,
                },
                {
                    Action    => 'StateUpdate',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    State     => 'closed',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 105,
                },
            ],
        },
        'created and closed within timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 55,    # Changed
                        $StatsStartSystemTime + 55,    # Closed
                        'closed',                      # State
                        1,                             # Queue
                        $StatsStartSystemTime + 5,     # QueueJoinTime
                        $StatsStartSystemTime + 55,    # QueueLeftTime
                        50,                            # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 5,
                },
                {
                    Action    => 'StateUpdate',                # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    State     => 'closed',                     # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 55,
                },
            ],
        },
        'created and closed with state in between within timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 55,    # Changed
                        $StatsStartSystemTime + 55,    # Closed
                        'closed',                      # State
                        1,                             # Queue
                        $StatsStartSystemTime + 5,     # QueueJoinTime
                        $StatsStartSystemTime + 55,    # QueueLeftTime
                        50,                            # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 5,
                },
                {
                    Action    => 'StateUpdate',                # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    State     => 'pending reminder',           # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 25,
                },
                {
                    Action    => 'StateUpdate',                # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    State     => 'closed',                     # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 55,
                },
            ],
        },
        'created, closed, reopened and reclosed within timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 55,    # Changed
                        $StatsStartSystemTime + 55,    # Closed
                        'closed',                      # State
                        1,                             # Queue
                        $StatsStartSystemTime + 5,     # QueueJoinTime
                        $StatsStartSystemTime + 55,    # QueueLeftTime
                        41,                            # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 5,
                },
                {
                    Action    => 'StateUpdate',                # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    State     => 'closed',                     # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 19,
                },
                {
                    Action    => 'StateUpdate',                # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    State     => 'pending reminder',           # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 28,
                },
                {
                    Action    => 'StateUpdate',                # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    State     => 'closed',                     # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 55,
                },
            ],
        },
        'created and moved between reported queues within timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 55,    # Changed
                        '',                            # Closed
                        'open',                        # State
                        1,                             # Queue
                        $StatsStartSystemTime + 5,     # QueueJoinTime
                        $StatsStartSystemTime + 55,    # QueueLeftTime
                        50,                            # RestingTimeSeconds
                    ],
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 55,    # Changed
                        '',                            # Closed
                        'open',                        # State
                        2,                             # Queue
                        $StatsStartSystemTime + 55,    # QueueJoinTime
                        '',                            # QueueLeftTime
                        45,                            # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 5,
                },
                {
                    Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 2,                            # 1, 2, or 3 (3 will not be reported)
                    TimeStamp => $StatsStartSystemTime + 55,
                },
            ],
        },
        'created and moved from non-reported to reported queue within timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 55,    # Changed
                        '',                            # Closed
                        'open',                        # State
                        2,                             # Queue
                        $StatsStartSystemTime + 55,    # QueueJoinTime
                        '',                            # QueueLeftTime
                        45,                            # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 3,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 5,
                },
                {
                    Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 2,                            # 1, 2, or 3 (3 will not be reported)
                    TimeStamp => $StatsStartSystemTime + 55,
                },
            ],
        },
        'created and moved from reported to non-reported queue within timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 55,    # Changed
                        '',                            # Closed
                        'open',                        # State
                        1,                             # Queue
                        $StatsStartSystemTime + 5,     # QueueJoinTime
                        $StatsStartSystemTime + 55,    # QueueLeftTime
                        50,                            # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 5,
                },
                {
                    Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 3,                            # 1, 2, or 3 (3 will not be reported)
                    TimeStamp => $StatsStartSystemTime + 55,
                },
            ],
        },
        'created and moved multiple times between reported queues within timeframe' => {
            ExpectedResult => {
                Listed => 1,    # 1 or 0
                Data   => [
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 95,    # Changed
                        '',                            # Closed
                        'open',                        # State
                        1,                             # Queue
                        $StatsStartSystemTime + 5,     # QueueJoinTime
                        $StatsStartSystemTime + 55,    # QueueLeftTime
                        50,                            # RestingTimeSeconds
                    ],
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 95,    # Changed
                        '',                            # Closed
                        'open',                        # State
                        2,                             # Queue
                        $StatsStartSystemTime + 55,    # QueueJoinTime
                        $StatsStartSystemTime + 65,    # QueueLeftTime
                        10,                            # RestingTimeSeconds
                    ],
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 95,    # Changed
                        '',                            # Closed
                        'open',                        # State
                        1,                             # Queue
                        $StatsStartSystemTime + 65,    # QueueJoinTime
                        $StatsStartSystemTime + 95,    # QueueLeftTime
                        30,                            # RestingTimeSeconds
                    ],
                    [
                        $StatsStartSystemTime + 5,     # Created
                        $StatsStartSystemTime + 95,    # Changed
                        '',                            # Closed
                        'open',                        # State
                        2,                             # Queue
                        $StatsStartSystemTime + 95,    # QueueJoinTime
                        '',                            # QueueLeftTime
                        5,                             # RestingTimeSeconds
                    ],
                ],
            },
            TicketData => [
                {
                    Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                    State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                    TimeStamp => $StatsStartSystemTime + 5,
                },
                {
                    Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 2,                            # 1, 2, or 3 (3 will not be reported)
                    TimeStamp => $StatsStartSystemTime + 55,
                },
                {
                    Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 1,                            # 1, 2, or 3 (3 will not be reported)
                    TimeStamp => $StatsStartSystemTime + 65,
                },
                {
                    Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                    Queue     => 2,                            # 1, 2, or 3 (3 will not be reported)
                    TimeStamp => $StatsStartSystemTime + 95,
                },
            ],
        },
        'start before timeframe, move, close, move, reopen, move back and forth, then close after timeframe'
            => {
                ExpectedResult => {
                    Listed => 1,    # 1 or 0
                    Data   => [
                        [
                            $StatsStartSystemTime - 5,      # Created
                            $StatsStartSystemTime + 101,    # Changed
                            $StatsStartSystemTime + 101,    # Closed
                            'closed',                       # State
                            1,                              # Queue
                            $StatsStartSystemTime - 5,      # QueueJoinTime
                            $StatsStartSystemTime + 3,      # QueueLeftTime
                            8,                              # RestingTimeSeconds
                        ],
                        [
                            $StatsStartSystemTime - 5,      # Created
                            $StatsStartSystemTime + 101,    # Changed
                            $StatsStartSystemTime + 101,    # Closed
                            'closed',                       # State
                            2,                              # Queue
                            $StatsStartSystemTime + 3,      # QueueJoinTime
                            $StatsStartSystemTime + 12,     # QueueLeftTime
                            9,                              # RestingTimeSeconds
                        ],
                        [
                            $StatsStartSystemTime - 5,      # Created
                            $StatsStartSystemTime + 101,    # Changed
                            $StatsStartSystemTime + 101,    # Closed
                            'closed',                       # State
                            1,                              # Queue
                            $StatsStartSystemTime + 19,     # QueueJoinTime
                            $StatsStartSystemTime + 30,     # QueueLeftTime
                            11,                             # RestingTimeSeconds
                        ],
                        [
                            $StatsStartSystemTime - 5,      # Created
                            $StatsStartSystemTime + 101,    # Changed
                            $StatsStartSystemTime + 101,    # Closed
                            'closed',                       # State
                            2,                              # Queue
                            $StatsStartSystemTime + 30,     # QueueJoinTime
                            $StatsStartSystemTime + 31,     # QueueLeftTime
                            1,                              # RestingTimeSeconds
                        ],
                        [
                            $StatsStartSystemTime - 5,      # Created
                            $StatsStartSystemTime + 101,    # Changed
                            $StatsStartSystemTime + 101,    # Closed
                            'closed',                       # State
                            2,                              # Queue
                            $StatsStartSystemTime + 80,     # QueueJoinTime
                            '',                             # QueueLeftTime
                            20,                             # RestingTimeSeconds
                        ],
                    ],
                },
                TicketData => [
                    {
                        Action    => 'NewTicket',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                        Queue     => 1,                           # 1, 2, or 3 (3 will not be reported)
                        State     => 'open',                      # 'open', 'pending reminder' or 'closed'
                        TimeStamp => $StatsStartSystemTime - 5,
                    },
                    {
                        Action    => 'Move',                      # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                        Queue     => 2,                           # 1, 2, or 3 (3 will not be reported)
                        TimeStamp => $StatsStartSystemTime + 3,
                    },
                    {
                        Action    => 'StateUpdate',                # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                        State     => 'closed',                     # 'open', 'pending reminder' or 'closed'
                        TimeStamp => $StatsStartSystemTime + 12,
                    },
                    {
                        Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                        Queue     => 1,                            # 1, 2, or 3 (3 will not be reported)
                        TimeStamp => $StatsStartSystemTime + 13,
                    },
                    {
                        Action    => 'StateUpdate',                # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                        State     => 'pending reminder',           # 'open', 'pending reminder' or 'closed'
                        TimeStamp => $StatsStartSystemTime + 19,
                    },
                    {
                        Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                        Queue     => 2,                            # 1, 2, or 3 (3 will not be reported)
                        TimeStamp => $StatsStartSystemTime + 30,
                    },
                    {
                        Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                        Queue     => 3,                            # 1, 2, or 3 (3 will not be reported)
                        TimeStamp => $StatsStartSystemTime + 31,
                    },
                    {
                        Action    => 'Move',                       # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                        Queue     => 2,                            # 1, 2, or 3 (3 will not be reported)
                        TimeStamp => $StatsStartSystemTime + 80,
                    },
                    {
                        Action    => 'StateUpdate',                 # 'NewTicket' (or empty), 'Move' or 'StateUpdate'
                        State     => 'closed',                      # 'open', 'pending reminder' or 'closed'
                        TimeStamp => $StatsStartSystemTime + 101,
                    },
                ],
            },
    };

    # prepare test-tickets  with 'real' queue names, state names and timestamps
    for my $Ticket ( sort keys %{$TestTickets} ) {
        for my $Data ( @{ $TestTickets->{$Ticket}->{ExpectedResult}->{Data} } ) {
            TIMEPARAM:
            for my $TimeParam ( 0 .. 2, 5, 6 ) {
                next TIMEPARAM if !$Data->[$TimeParam];
                $Data->[$TimeParam] = $Epoch2TimeStamp->(
                    Epoch => $Data->[$TimeParam],
                );
            }
            $Data->[3] = $States{ $Data->[3] };
            $Data->[4] = $Self->{UnitTestPrefix} . $Data->[4];
        }
        for my $Action ( @{ $TestTickets->{$Ticket}->{TicketData} } ) {
            if ( $Action->{Queue} ) {
                $Action->{Queue} = $Self->{UnitTestPrefix} . $Action->{Queue};
            }
            if ( $Action->{State} ) {
                $Action->{State} = $States{ $Action->{State} };
            }
            $Action->{TimeStamp} = $Epoch2TimeStamp->(
                Epoch => $Action->{TimeStamp},
            );
        }
    }
    return $TestTickets;
};

# get test ticket definition
my $TestTickets = $GetTestTicketDefinition->();

# get needed objects
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

# create and prepare test tickets
TICKET:
for my $Ticket ( sort keys %{$TestTickets} ) {
    my @Actions     = @{ $TestTickets->{$Ticket}->{TicketData} };
    my $FirstAction = shift @Actions;

    # set action time
    $HelperObject->FixedTimeSet(
        $TimeStamp2Epoch->( TimeStamp => $FirstAction->{TimeStamp} ),
    );

    my $TicketID = $TicketObject->TicketCreate(
        %{$FirstAction},
        Title      => $Self->{UnitTestPrefix} . '_' . $Ticket,
        Lock       => 'unlock',
        PriorityID => 1,
        OwnerID    => $UserID,
        UserID     => $UserID,
    );
    $Self->True(
        $TicketID,
        'Create test ticket ' . $TicketID,
    );
    next TICKET if !$TicketID;
    $TestTickets->{$Ticket}->{TicketID} = $TicketID;

    for my $Action (@Actions) {

        # set action time
        $HelperObject->FixedTimeSet(
            $TimeStamp2Epoch->( TimeStamp => $Action->{TimeStamp} ),
        );

        if ( $Action->{Action} eq 'Move' ) {
            my $MoveOk = $TicketObject->TicketQueueSet(
                Queue              => $Action->{Queue},
                TicketID           => $TicketID,
                UserID             => $UserID,
                SendNoNotification => 1,
            );
            $Self->True(
                $MoveOk,
                'Move test ticket ' . $TicketID,
            );
        }
        elsif ( $Action->{Action} eq 'StateUpdate' ) {
            my $StateOk = $TicketObject->TicketStateSet(
                State              => $Action->{State},
                TicketID           => $TicketID,
                UserID             => $UserID,
                SendNoNotification => 1,
            );
            $Self->True(
                $StateOk,
                'Change state of test ticket ' . $TicketID,
            );
        }
    }
}

# get cache object
my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

$CacheObject->CleanUp();

# run stat against test tickets
my $StatArray = $StatsObject->StatsRun(
    StatID   => $StatID,
    GetParam => $StatsRestrictions,
    UserID   => $UserID,
);
my @StatResult = @{$StatArray};
$Self->True(
    $StatResult[0],
    'Run Stat',
);

# remove (unneeded) stat headers
shift @StatResult;
shift @StatResult;
$Self->True(
    $StatResult[0],
    'Have Stat results',
);

# check stats result
TICKET:
for my $Ticket ( sort keys %{$TestTickets} ) {

    # filter stat result for ticket
    my $TicketID = $TestTickets->{$Ticket}->{TicketID};
    my @TicketStatData;
    RESULT:
    for my $Result (@StatResult) {
        next RESULT if $Result->[0] ne $TicketID;
        my @StoreResult = @{$Result};

        # Remove the first element (ticket id).
        shift @StoreResult;
        push @TicketStatData, \@StoreResult;
    }

    # check match for no expected result
    if ( !$TestTickets->{$Ticket}->{ExpectedResult}->{Listed} ) {

        # no data should be listed in stat result
        $Self->False(
            scalar @TicketStatData,
            "Expected no stat entry for test ticket $TicketID ($Ticket)",
        );
        next TICKET;
    }

    # check match for expected results
    my @ExpectedData = @{ $TestTickets->{$Ticket}->{ExpectedResult}->{Data} };
    $Self->IsDeeply(
        \@TicketStatData,
        \@ExpectedData,
        "Expected stat entries match for test ticket $TicketID ($Ticket)",
    );
}

# remove test tickets
for my $Ticket ( sort keys %{$TestTickets} ) {
    my $TicketID       = $TestTickets->{$Ticket}->{TicketID};
    my $TicketDeleteOk = $TicketObject->TicketDelete(
        TicketID => $TicketID,
        UserID   => $UserID,
    );
    $Self->True(
        $TicketDeleteOk,
        'Delete test ticket ' . $TicketID,
    );
}

# remove test stat
$Self->True(
    $StatsObject->StatsDelete( StatID => $StatID ),
    'Delete Stat',
);

# remove test queues
my $QueueRemoveOk = $Kernel::OM->Get('Kernel::System::DB')->Do(
    SQL  => 'DELETE FROM queue WHERE ID IN (?,?,?)',
    Bind => [ \$Queues{1}, \$Queues{2}, \$Queues{3}, ],
);
$Self->True(
    $QueueRemoveOk,
    'Remove test queues',
);
$CacheObject->CleanUp(
    Type => 'Queue',
);

1;
