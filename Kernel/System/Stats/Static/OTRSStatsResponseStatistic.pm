# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Stats::Static::OTRSStatsResponseStatistic;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Queue',
    'Kernel::System::StandardTemplate',
    'Kernel::System::Ticket',
    'Kernel::System::DateTime',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub GetObjectBehaviours {
    my ( $Self, %Param ) = @_;

    my %Behaviours = (
        ProvidesDashboardWidget => 1,
    );

    return %Behaviours;
}

sub Param {
    my $Self = shift;

    # Get current system datetime object.
    my $CurSysDTObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $CurrentYear    = $CurSysDTObject->Format( Format => '%Y' );
    my $CurrentMonth   = $CurSysDTObject->Format( Format => '%m' );

    # create possible time selections
    my %Year  = map { $_ => $_ } ( $CurrentYear - 10 .. $CurrentYear + 1 );
    my %Month = map { sprintf( "%02d", $_ ) => sprintf( "%02d", $_ ) } ( 1 .. 12 );
    my %Day   = map { sprintf( "%02d", $_ ) => sprintf( "%02d", $_ ) } ( 1 .. 31 );

    my @Params;

    push @Params, {
        Frontend   => Translatable('Start Day'),
        Name       => 'StartDay',
        Multiple   => 0,
        Size       => 0,
        SelectedID => '01',
        Data       => {
            %Day,
        },
    };

    push @Params, {
        Frontend   => Translatable('Start Month'),
        Name       => 'StartMonth',
        Multiple   => 0,
        Size       => 0,
        SelectedID => $CurrentMonth,
        Data       => {
            %Month,
        },
    };

    push @Params, {
        Frontend   => Translatable('Start Year'),
        Name       => 'StartYear',
        Multiple   => 0,
        Size       => 0,
        SelectedID => $CurrentYear,
        Data       => {
            %Year,
        },
    };

    push @Params, {
        Frontend   => Translatable('End Day'),
        Name       => 'EndDay',
        Multiple   => 0,
        Size       => 0,
        SelectedID => $CurSysDTObject->Format(
            Format => '%d',
        ),
        Data => {
            %Day,
        },
    };

    push @Params, {
        Frontend   => Translatable('End Month'),
        Name       => 'EndMonth',
        Multiple   => 0,
        Size       => 0,
        SelectedID => $CurrentMonth,
        Data       => {
            %Month,
        },
    };

    push @Params, {
        Frontend   => Translatable('End Year'),
        Name       => 'EndYear',
        Multiple   => 0,
        Size       => 0,
        SelectedID => $CurrentYear,
        Data       => {
            %Year,
        },
    };

    # get queues
    my %Queues = $Kernel::OM->Get('Kernel::System::Queue')->GetAllQueues();

    push @Params, {
        Frontend => Translatable('Queues'),
        Name     => 'QueueIDs',
        Multiple => 1,
        Size     => 10,
        Data     => \%Queues,
    };

    return @Params;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Param (qw(StartYear StartMonth StartDay EndYear EndMonth EndDay)) {
        if ( !$Param{$Param} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Param!",
            );
            return;
        }
    }

    # set start and end date
    my $StartDate = "$Param{StartYear}-$Param{StartMonth}-$Param{StartDay} 00:00:00";
    my $EndDate   = "$Param{EndYear}-$Param{EndMonth}-$Param{EndDay} 23:59:59";

    # get queue object
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    # get queues
    my %Queues   = $QueueObject->GetAllQueues();
    my @QueueIDs = keys %Queues;

    if ( @{ $Param{QueueIDs} } ) {

        # build list of selected queue ids
        @QueueIDs = @{ $Param{QueueIDs} };
    }

    # sort queue ids
    @QueueIDs = sort { $Queues{$a} cmp $Queues{$b} } @QueueIDs;

    # build array of queue names
    my @QueueNames = map { $Queues{$_} } @QueueIDs;

    # build queue string
    my $QueueString = Translatable('Queues: All');
    if ( scalar @QueueIDs < scalar keys %Queues ) {
        $QueueString = 'Queues: ' . join ', ', @QueueNames;
    }

    # set report title
    my $Title = '';
    $Title .= "($Param{StartDay}.$Param{StartMonth}.$Param{StartYear} - ";
    $Title .= "$Param{EndDay}.$Param{EndMonth}.$Param{EndYear}), ";
    $Title .= $QueueString;

    # table headlines
    my @HeadData = (
        'Response',
        @QueueNames,
        'Total',
    );

    # lookup history type
    my $MiscTypeID = $Kernel::OM->Get('Kernel::System::Ticket')->HistoryTypeLookup(
        Type => 'Misc',
    );

    # find all responses in history and count them
    my %ResponseCount;
    my %ResponseCountByQueueID;
    my $QueueIDString = join ', ', @QueueIDs;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    $DBObject->Prepare(
        SQL => "
            SELECT name, queue_id
            FROM ticket_history
            WHERE history_type_id = ?
                AND queue_id IN (" . $QueueIDString . ")
                AND create_time >= ?
                AND create_time <= ?
                AND name LIKE 'ResponseTemplate%'",
        Bind => [
            \$MiscTypeID,
            \$StartDate,
            \$EndDate,
        ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {

        # string looks like this: ResponseTemplate (1/3/4)
        if ( $Row[0] =~ m{ \A ResponseTemplate \s+ \( ( \d+ ) \/ }xms ) {

            my $ResponseID = $1;
            my $QueueID    = $Row[1];
            $ResponseCount{$ResponseID}++;
            $ResponseCountByQueueID{$ResponseID}->{$QueueID}++;
        }
    }

    my @Data;

    # sort responses by number (descending)
    for my $ResponseID ( sort { $ResponseCount{$b} <=> $ResponseCount{$a} } keys %ResponseCount ) {

        # lookup response name
        my $ResponseName = $Kernel::OM->Get('Kernel::System::StandardTemplate')->StandardTemplateLookup(
            StandardTemplateID => $ResponseID,
        );

        my @ResponseCountByQueue = ();
        for my $QueueID (@QueueIDs) {
            push @ResponseCountByQueue, $ResponseCountByQueueID{$ResponseID}->{$QueueID} || 0;
        }

        # build table row
        push @Data, [
            $ResponseName,
            @ResponseCountByQueue,
            $ResponseCount{$ResponseID},
        ];
    }

    return ( [$Title], [@HeadData], @Data );
}

1;
