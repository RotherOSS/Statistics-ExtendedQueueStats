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

package Kernel::System::Stats::Dynamic::OTOBOStatsQueueRestingTime;

use strict;
use warnings;

use List::Util qw( first );

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Log',
    'Kernel::System::Queue',
    'Kernel::System::Priority',
    'Kernel::System::State',
    'Kernel::System::Ticket',
    'Kernel::System::DateTime',
    'Kernel::System::Type',
    'Kernel::System::User',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get the dynamic fields for ticket object
    $Self->{DynamicField} = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Ticket'],
    );

    return $Self;
}

sub GetObjectName {
    my ( $Self, %Param ) = @_;

    return 'OTRSStatsQueueRestingTime';
}

sub GetObjectBehaviours {
    my ( $Self, %Param ) = @_;

    my %Behaviours = (
        ProvidesDashboardWidget => 0,
    );

    return %Behaviours;
}

sub GetObjectAttributes {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $ValidAgent = 0;
    if (
        defined $ConfigObject->Get('Stats::UseInvalidAgentInStats')
        && ( $ConfigObject->Get('Stats::UseInvalidAgentInStats') == 0 )
        )
    {
        $ValidAgent = 1;
    }

    # get user list
    my %UserList = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => $ValidAgent,
    );

    # get queue list
    my %QueueList = $Kernel::OM->Get('Kernel::System::Queue')->GetAllQueues();

    my %TicketAttributes = %{ $Self->_TicketAttributes() };
    my %OrderBy          = map { $_ => $TicketAttributes{$_} } grep { $_ ne 'Number' } keys %TicketAttributes;

    # remove non sortable (and orderable) Dynamic Fields
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

        # check if dynamic field is sortable
        my $IsSortable = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsSortable',
        );

        # remove dynamic fields from the list if is not sortable
        if ( !$IsSortable ) {
            delete $OrderBy{ 'DynamicField_' . $DynamicFieldConfig->{Name} };
        }
    }

    my %SortSequence = (
        Up   => Translatable('ascending'),
        Down => Translatable('descending'),
    );

    my @ObjectAttributes = (
        {
            Name                     => Translatable('Attributes to be printed'),
            UseAsXvalue              => 1,
            UseAsValueSeries         => 0,
            UseAsRestriction         => 0,
            Element                  => 'TicketAttributes',
            Block                    => 'MultiSelectField',
            Translation              => 1,
            Values                   => \%TicketAttributes,
            Sort                     => 'IndividualKey',
            SortIndividual           => $Self->_SortedAttributes(),
            DisableDefaultResultSort => 1,
        },
        {
            Name             => Translatable('Sort sequence'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 1,
            UseAsRestriction => 0,
            Element          => 'SortSequence',
            Block            => 'SelectField',
            Translation      => 1,
            Values           => \%SortSequence,
        },
        {
            Name             => Translatable('Queue'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'QueueIDs',
            Block            => 'MultiSelectField',
            Translation      => 0,
            TreeView         => 1,
            Values           => \%QueueList,
        },
        {
            Name             => Translatable('Reporting Timeslot'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'ReportingTimeslot',
            TimePeriodFormat => 'DateInputFormat',                    # 'DateInputFormatLong',
            Block            => 'Time',
            Values           => {
                TimeStart => 'ReportingTimeslotOlderDate',
                TimeStop  => 'ReportingTimeslotNewerDate',
            },
        },
    );

    if ( $ConfigObject->Get('Ticket::Type') ) {

        # get ticket type list
        my %Type = $Kernel::OM->Get('Kernel::System::Type')->TypeList(
            UserID => 1,
        );

        my %ObjectAttribute1 = (
            Name             => Translatable('Type'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'TypeIDs',
            Block            => 'MultiSelectField',
            Translation      => 0,
            Values           => \%Type,
        );

        unshift @ObjectAttributes, \%ObjectAttribute1;
    }

    return @ObjectAttributes;
}

sub GetStatTablePreview {
    my ( $Self, %Param ) = @_;

    return $Self->GetStatTable(
        %Param,
        Preview => 1,
    );
}

sub GetStatTable {
    my ( $Self, %Param ) = @_;
    my %TicketAttributes    = map { $_ => 1 } @{ $Param{XValue}->{SelectedValues} };
    my $SortedAttributesRef = $Self->_SortedAttributes();
    my $Preview             = $Param{Preview};

    # check if a enumeration is requested
    my $AddEnumeration = 0;
    if ( $TicketAttributes{Number} ) {
        $AddEnumeration = 1;
        delete $TicketAttributes{Number};
    }

    my $SortRef = first { $_->{Element} eq 'SortSequence' } @{ $Param{ValueSeries} };

    my $Sort = $SortRef ? $SortRef->{SelectedValues}->[0] : 'Up';

    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    # get all queues
    my %QueueList = $QueueObject->GetAllQueues();
    for my $Queue ( sort keys %QueueList ) {

        my %QueueData = $QueueObject->QueueGet(
            ID => $Queue,
        );
        $QueueList{$Queue} = \%QueueData;
    }

    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    # get all relevant states (exluding merged and removed state types)
    my %StateTypeList = $StateObject->StateTypeList( UserID => 1 );
    my @OpenStateTypes;
    my @ClosedStateTypes = ('closed');
    STATETYPE:
    for my $StateType ( sort values %StateTypeList ) {
        next STATETYPE if $StateType eq 'merged';
        next STATETYPE if $StateType eq 'removed';
        next STATETYPE if $StateType eq 'closed';
        push @OpenStateTypes, $StateType;
    }
    my %StateList  = $StateObject->StateList( UserID => 1 );
    my @OpenStates = $StateObject->StateGetStatesByType(
        StateType => \@OpenStateTypes,
        Result    => 'ID',
    );
    @OpenStates = grep { $StateList{$_} } @OpenStates;
    my @ClosedStates = $StateObject->StateGetStatesByType(
        StateType => \@ClosedStateTypes,
        Result    => 'ID',
    );
    @ClosedStates = grep { $StateList{$_} } @ClosedStates;

    # get relevant ticket types
    my @TicketTypeIDs;
    if ( IsArrayRefWithData( $Param{Restrictions}->{TypeIDs} ) ) {
        push @TicketTypeIDs, @{ $Param{Restrictions}->{TypeIDs} };
    }
    else {
        my %TicketTypes = $Kernel::OM->Get('Kernel::System::Type')->TypeList(
            UserID => 1,
        );
        @TicketTypeIDs = sort keys %TicketTypes;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $SQLTicketTypeIDs = '';
    if (@TicketTypeIDs) {

        my $SQLTicketTypeIDInCondition = $DBObject->QueryInCondition(
            Key       => 't.type_id',
            Values    => \@TicketTypeIDs,
            QuoteType => 'Integer',
            BindMode  => 0,
        );

        $SQLTicketTypeIDs = 'AND ' . $SQLTicketTypeIDInCondition;
    }

    # get history types
    return if !$DBObject->Prepare(
        SQL => '
            SELECT id, name
            FROM ticket_history_type',
        Limit => 100,
    );

    my %HistoryTypeList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $HistoryTypeList{ $Row[0] } = $Row[1];
    }
    my %HistoryTypeListReverse = reverse %HistoryTypeList;

    # get a limit for query results on ticket history
    my $TicketHistoryLimit = $Kernel::OM->Get('Kernel::Config')->Get('QueueRestingTime::HistorySearchLimit') || 50000;

    if ($Preview) {
        $TicketHistoryLimit = 20;
    }

    # get all history entries
    # - history entries of type Move to create the csv entries
    # - history entries of type NewTicket to specify the residence beginning of the first queue
    # - history entries of type StateUpdate to specify the end of residence of a queue
    return if !$DBObject->Prepare(
        SQL => '
            SELECT th.ticket_id, th.name, th.history_type_id, th.create_time, th.queue_id, th.state_id
            FROM ticket_history th, ticket t
            WHERE t.id = th.ticket_id
                ' . $SQLTicketTypeIDs . '
                AND th.create_time >= ?
                AND th.create_time <= ?
                AND th.history_type_id IN (?,?,?)
                AND th.state_id IN (' . join( ',', @OpenStates, @ClosedStates ) . ')
            ORDER BY th.create_time ASC',
        Bind => [
            \$Param{Restrictions}->{ReportingTimeslotOlderDate},
            \$Param{Restrictions}->{ReportingTimeslotNewerDate},
            \$HistoryTypeListReverse{NewTicket},
            \$HistoryTypeListReverse{Move},
            \$HistoryTypeListReverse{StateUpdate},
        ],
        Limit => $TicketHistoryLimit,
    );

    my %TicketList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Self->_PrepareTicketList(
            TicketList      => \%TicketList,
            SQLRow          => \@Row,
            HistoryTypeList => \%HistoryTypeList,
            %Param,
        );
    }

    if ( !$Preview ) {

        # get the ticket history entries that are relevant for the calculation
        return if !$DBObject->Prepare(
            SQL => "
            SELECT MIN(th.id)
            FROM ticket_history th
            WHERE th.create_time <= ?
                AND th.state_id IN (" . join( ',', @OpenStates, @ClosedStates ) . ")
                AND th.history_type_id IN (
                    '" . $HistoryTypeListReverse{NewTicket} . "',
                    '" . $HistoryTypeListReverse{StateUpdate} . "'
                    )
                AND th.create_time = (
                    SELECT MAX(th2.create_time)
                    FROM ticket_history th2
                    WHERE th2.ticket_id = th.ticket_id
                        AND th2.create_time <= ?
                        AND th2.history_type_id IN (
                            '" . $HistoryTypeListReverse{NewTicket} . "',
                            '" . $HistoryTypeListReverse{StateUpdate} . "'
                            )
                )
                GROUP BY th.ticket_id",
            Bind => [
                \$Param{Restrictions}->{ReportingTimeslotOlderDate},
                \$Param{Restrictions}->{ReportingTimeslotOlderDate},
            ],
        );

        my @TicketHistoryIDs;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            push @TicketHistoryIDs, $Row[0];
        }

        my $SQLTicketHistoryIDs = '';
        if (@TicketHistoryIDs) {

            my $SQLTicketHistoryIDInCondition = $DBObject->QueryInCondition(
                Key       => 'th.id',
                Values    => \@TicketHistoryIDs,
                QuoteType => 'Integer',
                BindMode  => 0,
            );
            $SQLTicketHistoryIDs = ' AND ' . $SQLTicketHistoryIDInCondition;
        }

        my $SQLOlder = '
            SELECT th.ticket_id, th.name, th.history_type_id, th.create_time, th.queue_id, th.state_id, th.id
            FROM ticket_history th, ticket t
            WHERE t.id = th.ticket_id
            ' . $SQLTicketTypeIDs . '
            ' . $SQLTicketHistoryIDs;

        return if !$DBObject->Prepare(
            SQL   => $SQLOlder,
            Limit => $TicketHistoryLimit,
        );

        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Self->_PrepareTicketList(
                TicketList      => \%TicketList,
                SQLRow          => \@Row,
                HistoryTypeList => \%HistoryTypeList,
                %Param,
            );
        }
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my @StatArray;
    TICKET:
    for my $TicketID ( sort keys %TicketList ) {
        my $Ticket = $TicketList{$TicketID};

        # sort entries for safety
        @{ $Ticket->{States} } = sort { $a->{CreateTime} cmp $b->{CreateTime} } @{ $Ticket->{States} };
        @{ $Ticket->{Queues} } = sort { $a->{QueueJoinTime} cmp $b->{QueueJoinTime} } @{ $Ticket->{Queues} };

        # set default create time
        if ( $Ticket->{CreateTime} eq '' ) {
            $Ticket->{CreateTime} = $Param{Restrictions}->{ReportingTimeslotOlderDate};

            # get last state of ticket
            my $LastStateHistory = $Ticket->{States}->[-1];
            if ( IsHashRefWithData($LastStateHistory) ) {

                # if we just have the last state of the ticket in the past (old tickets)
                # then we have to take 1 state before the current state
                $Ticket->{CreateState} = $LastStateHistory->{StateFrom};
            }
        }

        # first we get the history ticket data at the creation time of the ticket
        my (
            $CreateDateYear, $CreateDateMonth,  $CreateDateDay,
            $CreateDateHour, $CreateDateMinute, $CreateDateSecond
        ) = $Ticket->{CreateTime}
            =~ m{ (\d+)-(\d+)-(\d+) \s+ (\d+)\:(\d+)\:(\d+) }xms;

        my %HistoryDataCreateDate = $TicketObject->HistoryTicketGet(
            StopYear   => $CreateDateYear,
            StopMonth  => $CreateDateMonth,
            StopDay    => $CreateDateDay,
            StopHour   => $CreateDateHour,
            StopMinute => $CreateDateMinute,
            StopSecond => $CreateDateSecond,
            TicketID   => $TicketID,
        );

        my $TicketCreateTime = $Ticket->{CreateTime};

        # add first queue residence of ticket
        my $HistoryDataFirstQueue = {
            QueueJoinTime => $TicketCreateTime,
            QueueLeftTime => '',
            QueueFrom     => '',
            Queue         => $HistoryDataCreateDate{QueueID},
        };
        unshift @{ $Ticket->{Queues} }, $HistoryDataFirstQueue;

        # if we have no information about the first state (NewTicket) of the ticket
        # we create the first state with the information we have
        if (
            !IsArrayRefWithData( $Ticket->{States} )
            || (
                IsArrayRefWithData( $Ticket->{States} )
                && !exists $Ticket->{States}->[0]->{NewTicket}
            )
            )
        {

            # add first state of ticket
            my $HistoryDataFirstState = {
                CreateTime => $TicketCreateTime,
                StateFrom  => '',
                State      => $Ticket->{CreateState},
            };
            unshift @{ $Ticket->{States} }, $HistoryDataFirstState;
        }

        # START definition of the close time for the last queue in the ticket cascade of ticket close time
        # - take close time of creation of the ticket, if its directly closed on creation
        # - get last state of the ticket (in configured time period), if its closed set this date
        # - use the date of configured ReportingTimeslotNewerDate (end of report time period)
        # get last state of ticket
        my $LastStateHistory = $Ticket->{States}->[-1];

        if ( IsHashRefWithData($LastStateHistory) && $LastStateHistory->{State} =~ m{closed}xms ) {

            # use creation time of last close state
            $Ticket->{CloseTime} = $LastStateHistory->{CreateTime};
        }

        # END definition of the close time for the last queue in the ticket

        my $TicketCloseTime      = $Ticket->{CloseTime};
        my $TicketCloseTimestamp = '';
        if ($TicketCloseTime) {
            $TicketCloseTimestamp = $Self->_TimeStamp2Epoch( TimeStamp => $TicketCloseTime );
        }

        # don't allow tickets which a last close time before reporting time stamp
        my $ReportingTimeslotOlderTimestamp = $Self->_TimeStamp2Epoch(
            TimeStamp => $Param{Restrictions}->{ReportingTimeslotOlderDate},
        );

        if ( $TicketCloseTimestamp && $TicketCloseTimestamp < $ReportingTimeslotOlderTimestamp ) {
            next TICKET;
        }

        # in this loop
        # we're calculating the left time of each queue

        my $LastQueueIndex;
        my $QueueIndex = 0;
        while ( $QueueIndex <= $#{ $Ticket->{Queues} } ) {

            my %CurrentQueueHistory = %{ $Ticket->{Queues}->[$QueueIndex] };

            if ( defined $LastQueueIndex ) {

                # set the end of residence for the last ticket
                $Ticket->{Queues}->[$LastQueueIndex]->{QueueLeftTime} = $CurrentQueueHistory{QueueJoinTime};
            }
            $LastQueueIndex = $QueueIndex;

            $QueueIndex++;
        }

        # the last queue move does not have a left time
        # so we use the close time of the ticket
        my $LastQueueJoinTimestamp = $Self->_TimeStamp2Epoch(
            TimeStamp => $Ticket->{Queues}->[-1]->{QueueJoinTime}
        );

        if ( $TicketCloseTimestamp && $LastQueueJoinTimestamp > $TicketCloseTimestamp ) {

            # if the ticket moves with state closed to a another queue
            # we need the time of the queue move
            $Ticket->{Queues}->[-1]->{QueueLeftTime} = $Ticket->{Queues}->[-1]->{QueueJoinTime};
        }
        elsif ($TicketCloseTimestamp) {

            # use close time of the ticket
            $Ticket->{Queues}->[-1]->{QueueLeftTime} = $TicketCloseTime;
        }

        # in this loop
        # we're calculating the open times of the states
        my $LastStateIndex;
        my $StateIndex = 0;
        while ( $StateIndex <= $#{ $Ticket->{States} } ) {

            my %CurrentStateHistory = %{ $Ticket->{States}->[$StateIndex] };

            if ( defined $LastStateIndex && IsHashRefWithData( \%CurrentStateHistory ) ) {

                # if ticket opened between to states
                # then we calculate the open time for this ticket
                # e.g.
                # true
                # 10:50:00 Open
                # 16:00:00 Closed
                # false
                # 10:00 Closed
                # 15:00 open
                if (
                    $CurrentStateHistory{StateFrom}    !~ m{closed}xms
                    && $CurrentStateHistory{State}     !~ m{closed}xms
                    || $CurrentStateHistory{StateFrom} !~ m{closed}xms
                    && $CurrentStateHistory{State}     =~ m{closed}xms
                    )
                {
                    push @{ $Ticket->{OpenTimePeriods} }, {
                        StartTime => $Ticket->{States}->[$LastStateIndex]->{CreateTime},
                        EndTime   => $CurrentStateHistory{CreateTime},
                    };
                }

            }

            # set the last ticket index
            $LastStateIndex = $StateIndex;

            $StateIndex++;
        }

        # if a ticket is created without a close state
        # in time period of the report then
        # we calculate the open time for the last state
        my $StateCreateTimestamp = $Self->_TimeStamp2Epoch(
            TimeStamp => $Ticket->{States}->[-1]->{CreateTime},
        );
        if ( $Ticket->{States}->[-1]->{State} !~ m{closed}xms ) {
            push @{ $Ticket->{OpenTimePeriods} }, {
                StartTime => $Ticket->{States}->[-1]->{CreateTime},
                EndTime   => $Param{Restrictions}->{ReportingTimeslotNewerDate},
            };
        }

        # now we need the calculate the open times for
        # the all the queues the ticket had residence in
        # this calculations are based on the join and left time
        # of the ticket in the queue
        $QueueIndex = 0;
        while ( $QueueIndex <= $#{ $Ticket->{Queues} } ) {

            my $Queue              = $Ticket->{Queues}->[$QueueIndex];
            my $QueueJoinTimestamp = $Self->_TimeStamp2Epoch(
                TimeStamp => $Queue->{QueueJoinTime},
            );
            my $QueueLeftTimestamp = '';
            if ( $Queue->{QueueLeftTime} ) {
                $QueueLeftTimestamp = $Self->_TimeStamp2Epoch(
                    TimeStamp => $Queue->{QueueLeftTime},
                );
            }

            $Queue->{OpenTimePeriods} = [];

            # get open times of the ticket
            my @QueueOpenTimePeriods = @{ $Ticket->{OpenTimePeriods} };

            # get all open time periods of the ticket
            my $ValidMin;
            my $ValidMax;
            OPENPERIOD:
            for my $OpenPeriod (@QueueOpenTimePeriods) {

                my $OpenStart = $Self->_TimeStamp2Epoch( TimeStamp => $OpenPeriod->{StartTime} );
                my $OpenEnd   = $Self->_TimeStamp2Epoch( TimeStamp => $OpenPeriod->{EndTime} );

                # if open time period in the time period
                # of the ticket in queue
                # then we add the period to open time periods
                # of the queue
                $QueueLeftTimestamp ||= $Self->_TimeStamp2Epoch(
                    TimeStamp => $Param{Restrictions}->{ReportingTimeslotNewerDate}
                );
                next OPENPERIOD if $QueueLeftTimestamp && $OpenStart > $QueueLeftTimestamp;
                next OPENPERIOD if $OpenEnd < $QueueJoinTimestamp;

                my $Start     = $OpenStart > $QueueJoinTimestamp ? $OpenStart : $QueueJoinTimestamp;
                my $StartTime = $Self->_Epoch2TimeStamp(
                    Epoch => $Start,
                );
                my $End     = $QueueLeftTimestamp > $OpenEnd ? $OpenEnd : $QueueLeftTimestamp;
                my $EndTime = $Self->_Epoch2TimeStamp(
                    Epoch => $End,
                );

                # remember valid min and max times
                if ( !$ValidMin || $ValidMin > $Start ) {
                    $ValidMin = $Start;
                }
                if ( !$ValidMax || $ValidMax < $End ) {
                    $ValidMax = $End;
                }

                # add time period for queue based on
                # the period time where this ticket took residence in this queue
                push @{ $Queue->{OpenTimePeriods} }, {
                    StartTime => $StartTime,
                    EndTime   => $EndTime,
                };
            }

            # restrict if join and left times to valid boundaries
            if ( $ValidMin && $ValidMin > $QueueJoinTimestamp ) {
                $Queue->{QueueJoinTime} = $Self->_Epoch2TimeStamp(
                    Epoch => $ValidMin,
                );
            }
            if ( $ValidMax && $ValidMax < $QueueLeftTimestamp ) {
                $Queue->{QueueLeftTime} = $Self->_Epoch2TimeStamp(
                    Epoch => $ValidMax,
                );
            }

            # second step is to calculate a time-stamp
            # based on the open times of ticket in this queue
            $Queue->{RestingTimeSeconds}              = 0;
            $Queue->{RestingTimeWorkingPeriodSeconds} = 0;

            for my $OpenPeriod ( @{ $Queue->{OpenTimePeriods} } ) {

                my $OpenStart = $Self->_TimeStamp2Epoch( TimeStamp => $OpenPeriod->{StartTime} );
                my $OpenEnd   = $Self->_TimeStamp2Epoch( TimeStamp => $OpenPeriod->{EndTime} );

                # resting time
                $Queue->{RestingTimeSeconds} += $OpenEnd - $OpenStart;

                if ( $QueueList{ $Queue->{Queue} }->{Calendar} ne '' ) {

                    # calculate open times with work hour calender
                    # of the queue
                    $Queue->{RestingTimeWorkingPeriodSeconds} += $Self->_WorkingTime(
                        StartTime => $OpenStart,
                        StopTime  => $OpenEnd,
                        Calendar  => $QueueList{ $Queue->{Queue} }->{Calendar},
                    );
                }
            }

            # format resting times
            $Queue->{RestingTimeHR}              = $Self->_TimestampToDuration( Timestamp => $Queue->{RestingTimeSeconds} );
            $Queue->{RestingTimeWorkingPeriodHR} = $Self->_TimestampToDuration(
                Timestamp => $Queue->{RestingTimeWorkingPeriodSeconds}
            );

            $QueueIndex++;
        }

        # some of the ticket attributes can't be restored from the
        # history (e.g. Title), so we use the current data to avoid
        # blank spaces in the result
        my %ActualTicketData = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            UserID        => 1,
            DynamicFields => 1,
            Extended      => 1,
        );

        QUERY:
        for my $QueueEntry ( @{ $Ticket->{Queues} } ) {

            # only output configured queues
            next QUERY if !grep { $_ == $QueueEntry->{Queue} } @{ $Param{Restrictions}->{QueueIDs} };

            $QueueEntry->{TicketNumber} = $HistoryDataCreateDate{TicketNumber};
            $QueueEntry->{Queue}        = $QueueList{ $QueueEntry->{Queue} }->{Name};

            my @ResultRow;
            ATTRIBUTE:
            for my $Attribute ( @{$SortedAttributesRef} ) {
                next ATTRIBUTE if !$TicketAttributes{$Attribute};

                my $ResultValue = defined $QueueEntry->{$Attribute} ? $QueueEntry->{$Attribute} : '';
                if ( $ResultValue eq '' && $ActualTicketData{$Attribute} ) {
                    $ResultValue = $ActualTicketData{$Attribute};
                }
                push @ResultRow, $ResultValue;
            }
            push @StatArray, \@ResultRow;
        }
    }

    # sort by ticket number
    my $TicketNumberKey  = 0;
    my $TicketIDKey      = 0;
    my $QueueJoinTimeKey = 0;
    ATTRIBUTE:
    for my $Attribute ( @{$SortedAttributesRef} ) {
        if ( $TicketAttributes{$Attribute} ) {
            $TicketNumberKey++;
        }
        last ATTRIBUTE if $Attribute eq 'TicketNumber';
    }

    # replace ticket number with ticket id if ticket number is not configured
    if ( !$TicketNumberKey ) {
        ATTRIBUTE:
        for my $Attribute ( @{$SortedAttributesRef} ) {
            if ( $TicketAttributes{$Attribute} ) {
                $TicketNumberKey++;
            }
            last ATTRIBUTE if $Attribute eq 'TicketID';

        }
    }

    ATTRIBUTE:
    for my $Attribute ( @{$SortedAttributesRef} ) {
        if ( $TicketAttributes{$Attribute} ) {
            $QueueJoinTimeKey++;
        }
        last ATTRIBUTE if $Attribute eq 'QueueJoinTime';
    }

    # remove 1 because array index starts at 0
    $TicketNumberKey--;
    $QueueJoinTimeKey--;

    # sort by ticket number asc or desc
    # secondary sort by queue join time
    @StatArray = sort {
        if ( $a->[$TicketNumberKey] eq $b->[$TicketNumberKey] ) {
            my $AQueueJoinTime = $Self->_TimeStamp2Epoch(
                TimeStamp => $a->[$QueueJoinTimeKey],
            );
            my $BQueueJoinTime = $Self->_TimeStamp2Epoch(
                TimeStamp => $b->[$QueueJoinTimeKey],
            );
            return $AQueueJoinTime <=> $BQueueJoinTime;
        }
        return ( $Sort eq 'Up' )
            ? $a->[$TicketNumberKey] <=> $b->[$TicketNumberKey]
            : $b->[$TicketNumberKey] <=> $a->[$TicketNumberKey];
    } @StatArray;

    # add a enumeration in front of each row
    if ($AddEnumeration) {
        my $Counter = 0;
        for my $Row (@StatArray) {
            unshift @{$Row}, ++$Counter;
        }
    }

    return @StatArray;
}

sub GetHeaderLine {
    my ( $Self, %Param ) = @_;
    my %SelectedAttributes = map { $_ => 1 } @{ $Param{XValue}->{SelectedValues} };

    my $TicketAttributes    = $Self->_TicketAttributes();
    my $SortedAttributesRef = $Self->_SortedAttributes();
    my @HeaderLine;

    ATTRIBUTE:
    for my $Attribute ( @{$SortedAttributesRef} ) {
        next ATTRIBUTE if !$SelectedAttributes{$Attribute};
        push @HeaderLine, $TicketAttributes->{$Attribute};
    }
    return \@HeaderLine;
}

sub ExportWrapper {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $UserObject     = $Kernel::OM->Get('Kernel::System::User');
    my $QueueObject    = $Kernel::OM->Get('Kernel::System::Queue');
    my $StateObject    = $Kernel::OM->Get('Kernel::System::State');
    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    # wrap ids to used spelling
    for my $Use (qw(UseAsValueSeries UseAsRestriction UseAsXvalue)) {
        ELEMENT:
        for my $Element ( @{ $Param{$Use} } ) {
            next ELEMENT if !$Element || !$Element->{SelectedValues};
            my $ElementName = $Element->{Element};
            my $Values      = $Element->{SelectedValues};

            if ( $ElementName eq 'QueueIDs' || $ElementName eq 'CreatedQueueIDs' ) {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    $ID->{Content} = $QueueObject->QueueLookup( QueueID => $ID->{Content} );
                }
            }
            elsif ( $ElementName eq 'StateIDs' || $ElementName eq 'CreatedStateIDs' ) {
                my %StateList = $StateObject->StateList( UserID => 1 );
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    $ID->{Content} = $StateList{ $ID->{Content} };
                }
            }
            elsif ( $ElementName eq 'PriorityIDs' || $ElementName eq 'CreatedPriorityIDs' ) {
                my %PriorityList = $PriorityObject->PriorityList( UserID => 1 );
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    $ID->{Content} = $PriorityList{ $ID->{Content} };
                }
            }
            elsif (
                $ElementName eq 'OwnerIDs'
                || $ElementName eq 'CreatedUserIDs'
                || $ElementName eq 'ResponsibleIDs'
                )
            {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    $ID->{Content} = $UserObject->UserLookup( UserID => $ID->{Content} );
                }
            }

            # Locks and statustype don't have to wrap because they are never different
        }
    }
    return \%Param;
}

sub ImportWrapper {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $UserObject     = $Kernel::OM->Get('Kernel::System::User');
    my $QueueObject    = $Kernel::OM->Get('Kernel::System::Queue');
    my $StateObject    = $Kernel::OM->Get('Kernel::System::State');
    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    # wrap used spelling to ids
    for my $Use (qw(UseAsValueSeries UseAsRestriction UseAsXvalue)) {
        ELEMENT:
        for my $Element ( @{ $Param{$Use} } ) {
            next ELEMENT if !$Element || !$Element->{SelectedValues};
            my $ElementName = $Element->{Element};
            my $Values      = $Element->{SelectedValues};

            if ( $ElementName eq 'QueueIDs' || $ElementName eq 'CreatedQueueIDs' ) {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    if ( $QueueObject->QueueLookup( Queue => $ID->{Content} ) ) {
                        $ID->{Content} = $QueueObject->QueueLookup( Queue => $ID->{Content} );
                    }
                    else {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "Import: Can' find the queue $ID->{Content}!"
                        );
                        $ID = undef;
                    }
                }
            }
            elsif ( $ElementName eq 'StateIDs' || $ElementName eq 'CreatedStateIDs' ) {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;

                    my %State = $StateObject->StateGet(
                        Name  => $ID->{Content},
                        Cache => 1,
                    );
                    if ( $State{ID} ) {
                        $ID->{Content} = $State{ID};
                    }
                    else {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "Import: Can' find state $ID->{Content}!"
                        );
                        $ID = undef;
                    }
                }
            }
            elsif ( $ElementName eq 'PriorityIDs' || $ElementName eq 'CreatedPriorityIDs' ) {
                my %PriorityList = $PriorityObject->PriorityList( UserID => 1 );
                my %PriorityIDs;
                for my $Key ( sort keys %PriorityList ) {
                    $PriorityIDs{ $PriorityList{$Key} } = $Key;
                }
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;

                    if ( $PriorityIDs{ $ID->{Content} } ) {
                        $ID->{Content} = $PriorityIDs{ $ID->{Content} };
                    }
                    else {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "Import: Can' find priority $ID->{Content}!"
                        );
                        $ID = undef;
                    }
                }
            }
            elsif (
                $ElementName eq 'OwnerIDs'
                || $ElementName eq 'CreatedUserIDs'
                || $ElementName eq 'ResponsibleIDs'
                )
            {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;

                    if ( $UserObject->UserLookup( UserLogin => $ID->{Content} ) ) {
                        $ID->{Content} = $UserObject->UserLookup(
                            UserLogin => $ID->{Content}
                        );
                    }
                    else {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "Import: Can' find user $ID->{Content}!"
                        );
                        $ID = undef;
                    }
                }
            }

            # Locks and statustype don't have to wrap because they are never different
        }
    }
    return \%Param;
}

sub _TicketAttributes {
    my $Self = shift;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %TicketAttributes = (
        Number                          => Translatable('Number'),
        TicketNumber                    => $ConfigObject->Get('Ticket::Hook'),
        TicketID                        => Translatable('Ticket ID'),
        Created                         => Translatable('Created'),
        Changed                         => Translatable('Changed'),
        Closed                          => Translatable('Close Time'),
        State                           => Translatable('State'),
        Queue                           => Translatable('Queue'),
        QueueJoinTime                   => Translatable('Queue join time'),
        QueueLeftTime                   => Translatable('Queue left time'),
        RestingTimeSeconds              => Translatable('Resting time (seconds)'),
        RestingTimeHR                   => Translatable('Resting time (HH:MM:SS)'),
        RestingTimeWorkingPeriodSeconds => Translatable('Resting time (Working hours, seconds)'),
        RestingTimeWorkingPeriodHR      => Translatable('Resting time (Working hours, HH:MM:SS)'),
    );

    if ( $ConfigObject->Get('Ticket::Type') ) {
        $TicketAttributes{Type} = 'Type';
    }

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

        $TicketAttributes{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $DynamicFieldConfig->{Label};
    }

    return \%TicketAttributes;
}

sub _PrepareTicketList {
    my ( $Self, %Param ) = @_;

    my $TicketList = $Param{TicketList};
    my @Row        = @{ $Param{SQLRow} };

    my $TicketID             = $Row[0];
    my $HistoryRawData       = $Row[1];
    my $HistoryType          = $Param{HistoryTypeList}->{ $Row[2] };
    my $HistoryCreateTime    = $Row[3];
    my $QueueID              = $Row[4];
    my $HistoryCreateStateID = $Row[5];

    my @HistoryTmp = split( '%%', $HistoryRawData );
    my %StateList  = $Kernel::OM->Get('Kernel::System::State')->StateList( UserID => 1 );

    my $HistoryData = {};

    my $ReportingTimeslotOlderTimestamp = $Self->_TimeStamp2Epoch(
        TimeStamp => $Param{Restrictions}->{ReportingTimeslotOlderDate},
    );
    my $HistoryCreateTimestamp = $Self->_TimeStamp2Epoch(
        TimeStamp => $HistoryCreateTime,
    );

    # default structure of a ticket
    if ( !exists $TicketList->{$TicketID} ) {
        $TicketList->{$TicketID} = {
            Queues          => [],
            States          => [],
            CreateTime      => '',
            CreateState     => '',
            CloseTime       => '',
            OpenTimePeriods => [],
        };
    }

    if ( $HistoryType eq 'Move' ) {

        # add queue data of ticket
        my $Queue     = $HistoryTmp[2];
        my $QueueFrom = $HistoryTmp[4];

        $HistoryData = {
            QueueJoinTime => $HistoryCreateTime,
            QueueLeftTime => '',
            QueueFrom     => $QueueFrom,
            Queue         => $Queue,
        };

        push @{ $TicketList->{$TicketID}->{Queues} }, $HistoryData;
    }
    elsif ( $HistoryType eq 'NewTicket' ) {

        # add creation time of ticket
        $TicketList->{$TicketID}->{CreateTime}  = $HistoryCreateTime;
        $TicketList->{$TicketID}->{CreateState} = $StateList{$HistoryCreateStateID};

        # add first state of the ticket
        $HistoryData = {
            CreateTime => $HistoryCreateTime,
            StateFrom  => '',
            State      => $StateList{$HistoryCreateStateID},
            QueueID    => $QueueID,
            NewTicket  => 1,
        };

        push @{ $TicketList->{$TicketID}->{States} }, $HistoryData;
    }
    elsif ( $HistoryType eq 'StateUpdate' ) {

        # get a list of all states of a ticket
        my $FromState = $HistoryTmp[1];
        my $ToState   = $HistoryTmp[2];

        $HistoryData = {
            CreateTime => $HistoryCreateTime,
            StateFrom  => $FromState,
            State      => $ToState,
            QueueID    => $QueueID,
        };

        push @{ $TicketList->{$TicketID}->{States} }, $HistoryData;
    }

    return 1;
}

sub _TimestampToDuration {
    my ( $Self, %Param ) = @_;

    for (qw(Timestamp)) {
        if ( !defined $Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "_TimestampToDuration: Need $_!"
            );
            return;
        }
    }

    my $Hours   = 0;
    my $Minutes = 0;
    my $Seconds = 0;
    if ( $Param{Timestamp} > 0 ) {
        $Hours = int( $Param{Timestamp} / 3600 );
        $Param{Timestamp} -= $Hours * 3600;

        $Minutes = int( $Param{Timestamp} / 60 );
        $Seconds = $Param{Timestamp} % 60;
    }
    return
        sprintf( "%02d", $Hours ) . ":"
        . sprintf( "%02d", $Minutes ) . ":"
        . sprintf( "%02d", $Seconds );
}

sub _SortedAttributes {
    my $Self = shift;

    my @SortedAttributes = qw(
        Number
        TicketNumber
        TicketID
        Created
        Changed
        Closed
        State
        Type
        Queue
        QueueJoinTime
        QueueLeftTime
        RestingTimeSeconds
        RestingTimeHR
        RestingTimeWorkingPeriodSeconds
        RestingTimeWorkingPeriodHR
    );

    # cycle through the Dynamic Fields
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

        # add dynamic field attribute
        push @SortedAttributes, 'DynamicField_' . $DynamicFieldConfig->{Name};
    }

    return \@SortedAttributes;
}

sub _TimeStamp2Epoch {
    my ( $Self, %Param, ) = @_;

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $Param{TimeStamp},
        },
    );

    return $DateTimeObject->ToEpoch() if $DateTimeObject;
    return;
}

sub _Epoch2TimeStamp {
    my ( $Self, %Param, ) = @_;

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            Epoch => $Param{Epoch},
        },
    );

    return $DateTimeObject->ToString() if $DateTimeObject;
    return;
}

sub _WorkingTime {
    my ( $Self, %Param, ) = @_;

    my $StartTime = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            Epoch => $Param{StartTime},
        },
    );
    my $StopTime = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            Epoch => $Param{StopTime},
        },
    );

    my $Delta = $StartTime->Delta(
        DateTimeObject => $StopTime,
        Calendar       => $Param{Calendar},
        ForWorkingTime => 1,
    );

    return $Delta->{AbsoluteSeconds} || 0;
}

1;
