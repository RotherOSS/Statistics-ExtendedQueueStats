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

# define local variables
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

# get stats object
my $StatsObject = $Kernel::OM->Get('Kernel::System::Stats');

$Self->{UnitTestPrefix} = 'UnitTest-OTRSStatsResponseStatistic';

# add stats
my $StatID = $StatsObject->StatsAdd( UserID => $UserID );
$Self->True(
    $StatID > 0,
    'Create Stat',
);

my $Update = $StatsObject->StatsUpdate(
    StatID => $StatID,
    Hash   => {
        Title        => 'OTRSStatsResponseStatistic Unit Test',
        Description  => 'Test Results',
        Object       => '',
        Format       => ['CSV'],
        ObjectModule => 'Kernel::System::Stats::Static::OTRSStatsResponseStatistic',
        Permission   => ['1'],
        StatType     => 'static',
        Valid        => '1',
    },
    UserID => $UserID,
);
$Self->True(
    $Update,
    'Update Stat',
);

my $RandomID = $HelperObject->GetRandomID();

# get queue object
my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

# create test queues
my %Queues;
for my $Number ( 1 .. 3 ) {
    my $QueueID = $QueueObject->QueueAdd(
        Name            => $Self->{UnitTestPrefix} . $Number . $RandomID,
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

# get standard template object
my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

# create response templates
my %ResponseTemplates;
for my $Number ( 1 .. 3 ) {
    my $ResponseTemplateID = $StandardTemplateObject->StandardTemplateAdd(
        Name         => $Self->{UnitTestPrefix} . $Number . $RandomID,
        Template     => 'Thank you for your email.',
        ContentType  => 'text/plain; charset=utf-8',
        TemplateType => 'Answer',
        ValidID      => 1,
        UserID       => $UserID,
    );
    $Self->True(
        $ResponseTemplateID,
        'RemposeTemplate test queue ' . $Number,
    );
    $ResponseTemplates{$Number} = $ResponseTemplateID;
}

# definition of tests
my @Tests = (
    {
        Name            => 'Single response without timeframe',
        ExpectedResults => {
            $ResponseTemplates{1} => [
                0,    # Templates for Queue 1
                0,    # Templates for Queue 2
                0,    # Total
            ]
        },
        TicketData => [
            {
                Action    => 'NewTicket',             # 'NewTicket' (or empty), 'Response'
                QueueID   => $Queues{1},              # 1, 2, or 3 (3 will not be reported)
                TimeStamp => '1989-12-30 17:00:00',
            },
            {
                Action     => 'Response',              # 'NewTicket' (or empty), 'Response'
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-30 17:01:00',
            },
        ],
    },
    {
        Name            => 'Single response within timeframe',
        ExpectedResults => {
            $ResponseTemplates{1} => [
                1,
                0,
                1,
            ]
        },
        TicketData => [
            {
                Action    => 'NewTicket',
                QueueID   => $Queues{1},
                TimeStamp => '1989-12-31 17:00:00',
            },
            {
                Action     => 'Response',
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:01:00',
            },
        ],
    },
    {
        Name            => 'Single response within timeframe (not counted queue)',
        ExpectedResults => {},
        TicketData      => [
            {
                Action    => 'NewTicket',
                QueueID   => $Queues{1},
                TimeStamp => '1989-12-31 17:00:00',
            },
            {
                Action     => 'Response',
                QueueID    => $Queues{3},
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:01:00',
            },
        ],
    },
    {
        Name            => 'Multiple response within timeframe (same queue)',
        ExpectedResults => {
            $ResponseTemplates{1} => [
                3,
                0,
                3,
            ]
        },
        TicketData => [
            {
                Action    => 'NewTicket',
                QueueID   => $Queues{1},
                TimeStamp => '1989-12-31 17:00:00',
            },
            {
                Action     => 'Response',
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:01:00',
            },
            {
                Action     => 'Response',
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:02:00',
            },
            {
                Action     => 'Response',
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:02:00',
            },
        ],
    },
    {
        Name            => 'Multiple response within timeframe (same queue) different responses',
        ExpectedResults => {
            $ResponseTemplates{1} => [
                1,
                0,
                1,
            ],
            $ResponseTemplates{2} => [
                2,
                0,
                2,
            ],
        },
        TicketData => [
            {
                Action    => 'NewTicket',
                QueueID   => $Queues{1},
                TimeStamp => '1989-12-31 17:00:00',
            },
            {
                Action     => 'Response',
                ResponseID => $ResponseTemplates{2},
                TimeStamp  => '1989-12-31 17:01:00',
            },
            {
                Action     => 'Response',
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:02:00',
            },
            {
                Action     => 'Response',
                ResponseID => $ResponseTemplates{2},
                TimeStamp  => '1989-12-31 17:02:00',
            },
        ],
    },
    {
        Name            => 'Multiple response within timeframe (different queues) different responses 2',
        ExpectedResults => {
            $ResponseTemplates{1} => [
                1,
                1,
                2,
            ],
            $ResponseTemplates{2} => [
                1,
                1,
                2,
            ],
        },
        TicketData => [
            {
                Action    => 'NewTicket',
                QueueID   => $Queues{1},
                TimeStamp => '1989-12-31 17:00:00',
            },
            {
                Action     => 'Response',
                QueueID    => $Queues{2},
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:01:00',
            },
            {
                Action     => 'Response',
                QueueID    => $Queues{2},
                ResponseID => $ResponseTemplates{2},
                TimeStamp  => '1989-12-31 17:02:00',
            },
            {
                Action     => 'Response',
                QueueID    => $Queues{1},
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:03:00',
            },
            {
                Action     => 'Response',
                QueueID    => $Queues{1},
                ResponseID => $ResponseTemplates{2},
                TimeStamp  => '1989-12-31 17:04:00',
            },
        ],
    },
    {
        Name            => 'Multiple response within timeframe (different queues) same responses',
        ExpectedResults => {
            $ResponseTemplates{1} => [
                2,
                2,
                4,
            ],
        },
        TicketData => [
            {
                Action    => 'NewTicket',
                QueueID   => $Queues{1},
                TimeStamp => '1989-12-31 17:00:00',
            },
            {
                Action     => 'Response',
                QueueID    => $Queues{2},
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:01:00',
            },
            {
                Action     => 'Response',
                QueueID    => $Queues{2},
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:02:00',
            },
            {
                Action     => 'Response',
                QueueID    => $Queues{1},
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:03:00',
            },
            {
                Action     => 'Response',
                QueueID    => $Queues{1},
                ResponseID => $ResponseTemplates{1},
                TimeStamp  => '1989-12-31 17:04:00',
            },
        ],
    },
);

my %ExpectedResults;

# get needed objects
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

# set action time
$HelperObject->FixedTimeSet(
    $TimeStamp2Epoch->( TimeStamp => '1989-12-31 17:00:00' ),
);

# execute tests
TEST:
for my $Test (@Tests) {
    my @Actions     = @{ $Test->{TicketData} };
    my $FirstAction = shift @Actions;

    # set action time
    if ( $FirstAction->{TimeStamp} ne '1989-12-31 17:00:00' ) {
        $HelperObject->FixedTimeSet(
            $TimeStamp2Epoch->( TimeStamp => $FirstAction->{TimeStamp} ),
        );
    }

    my $TicketID = $TicketObject->TicketCreate(
        %{$FirstAction},
        Title      => $Self->{UnitTestPrefix} . '_' . $Test->{Name},
        Lock       => 'unlock',
        State      => 'open',
        PriorityID => 1,
        OwnerID    => $UserID,
        UserID     => $UserID,
    );
    $Self->True(
        $TicketID,
        'Create test ticket ' . $TicketID,
    );
    next TICKET if !$TicketID;

    # use any ArticleIDs as they are not checked
    my $ReplyArticleID = 1;
    my $ArticleID      = 1;

    for my $Action (@Actions) {

        # set action time
        $HelperObject->FixedTimeSet(
            $TimeStamp2Epoch->( TimeStamp => $Action->{TimeStamp} ),
        );

        if ( $Action->{Action} eq 'Response' ) {

            if ( $Action->{QueueID} ) {
                my $MoveOk = $TicketObject->TicketQueueSet(
                    QueueID            => $Action->{QueueID},
                    TicketID           => $TicketID,
                    UserID             => $UserID,
                    SendNoNotification => 1,
                );
                $Self->True(
                    $MoveOk,
                    'Move test ticket ' . $TicketID,
                );
            }

            # simulate that a response history entry has been added
            my $HistoryAddsuccess = $TicketObject->HistoryAdd(
                Name         => "ResponseTemplate ($Action->{ResponseID}/$ReplyArticleID/$ArticleID)",
                HistoryType  => 'Misc',
                TicketID     => $TicketID,
                CreateUserID => $UserID,
            );

            $Self->True(
                $HistoryAddsuccess,
                'Simulated response history added for ' . $TicketID,
            );
        }
    }

    # sum expected results
    # set them on a structure easy to compare
    RESPONSEID:
    for my $ResponseID ( sort keys %{ $Test->{ExpectedResults} } ) {
        my $Index = 0;
        for my $Value ( @{ $Test->{ExpectedResults}->{$ResponseID} } ) {

            # get response name
            my $Response = $StandardTemplateObject->StandardTemplateLookup(
                StandardTemplateID => $ResponseID,
            );

            $ExpectedResults{$Response}->[$Index] += $Value;
            $Index++;
        }
    }
}

# clear cache
$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

# run stat against test tickets
my $StatArray = $StatsObject->StatsRun(
    StatID   => $StatID,
    GetParam => {
        StartYear  => 1989,
        StartMonth => 12,
        StartDay   => 31,
        EndYear    => 1990,
        EndMonth   => 1,
        EndDay     => 1,
        QueueIDs   => [ $Queues{1}, $Queues{2} ]
    },
    UserID => $UserID,
);
my @StatResults = @{$StatArray};
$Self->True(
    $StatResults[0],
    'Run Stat',
);

# remove (unneeded) stat headers
shift @StatResults;
shift @StatResults;
$Self->True(
    $StatResults[0],
    'Have Stat results',
);

my %StatData;

# check stats result
RESULT:
for my $Result (@StatResults) {

    # discard results from other templates
    next RESULT if $Result->[0] !~ m{UnitTest-OTRSStatsResponseStatistic[1|2]test\d+};

    my @StoreResult = @{$Result};

    # remove first element (response template name)
    my $Response = splice @StoreResult, 0, 1;

    # set them in a structure easy to compare
    $StatData{$Response} = \@StoreResult;
}

# actual test result
$Self->IsDeeply(
    \%StatData,
    \%ExpectedResults,
    'Statistic results',
);

# no cleanup is needed as the unit test rolls back the transaction

1;
