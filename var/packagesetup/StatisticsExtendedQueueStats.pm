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

package var::packagesetup::StatisticsExtendedQueueStats;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Main',
    'Kernel::System::Stats',
    'Kernel::System::SysConfig',
    'Kernel::System::XML',
);

=head1 NAME

var::packagesetup::StatisticsExtendedQueueStats - code to execute during package installation

=head1 PUBLIC INTERFACE

=cut

=head2 new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $CodeObject = $Kernel::OM->Get('var::packagesetup::ExtendedTicketStats');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = bless {}, $Type;

    # Force a reload of ZZZAuto.pm and ZZZAAuto.pm to get the fresh configuration values.
    for my $Module ( sort keys %INC ) {
        if ( $Module =~ m/ZZZAA?uto\.pm$/ ) {
            delete $INC{$Module};
        }
    }

    # Create common objects with fresh default config.
    $Kernel::OM->ObjectsDiscard();

    # define UserID parameter for the constructor of the stats object
    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::Stats' => {
            UserID => 1,
        },
    );

    # define file prefix
    $Self->{FilePrefix} = 'OTOBOStats';

    return $Self;
}

=head2 CodeInstall()

run the code install part

    my $Result = $CodeObject->CodeInstall();

=cut

sub CodeInstall {
    my ( $Self, %Param ) = @_;

    # rename potentially existing stats from merged package
    $Self->_StatsRename();

    # install stats
    $Kernel::OM->Get('Kernel::System::Stats')->StatsInstall(
        FilePrefix => $Self->{FilePrefix},
        UserID     => 1,
    );

    return 1;
}

=head2 CodeReinstall()

run the code reinstall part

    my $Result = $CodeObject->CodeReinstall();

=cut

sub CodeReinstall {
    my ( $Self, %Param ) = @_;

    # install stats
    $Kernel::OM->Get('Kernel::System::Stats')->StatsInstall(
        FilePrefix => $Self->{FilePrefix},
        UserID     => 1,
    );

    return 1;
}

=head2 CodeUpgrade()

run the code upgrade part

    my $Result = $CodeObject->CodeUpgrade();

=cut

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    # install stats
    $Kernel::OM->Get('Kernel::System::Stats')->StatsInstall(
        FilePrefix => $Self->{FilePrefix},
        UserID     => 1,
    );

    return 1;
}

=head2 CodeUninstall()

run the code uninstall part

    my $Result = $CodeObject->CodeUninstall();

=cut

sub CodeUninstall {
    my ( $Self, %Param ) = @_;

    # uninstall stats
    $Kernel::OM->Get('Kernel::System::Stats')->StatsUninstall(
        FilePrefix => $Self->{FilePrefix},
        UserID     => 1,
    );

    return 1;
}

sub _StatsRename {
    my ( $Self, %Param ) = @_;

    my $XMLObject = $Kernel::OM->Get('Kernel::System::XML');

    # fetch relevant data - use List as conditions for Search are unpleasant to read
    my @Keys = $XMLObject->XMLHashList(
        Type => 'Stats',
    );

    KEY:
    for my $Key (@Keys) {
        my @XMLHash = $XMLObject->XMLHashGet(
            Type => 'Stats',
            Key  => $Key,
        );

        next KEY unless @XMLHash;

        # replace ObjectModule name
        {
            my $Name = $XMLHash[0]{'otobo_stats'}[1]{ObjectModule}[1]{Content};

            next KEY
                unless (
                    $Name eq 'Kernel::System::Stats::Dynamic::OTRSStatsQueueWorkingTime'
                    || $Name eq 'Kernel::System::Stats::Dynamic::OTRSStatsQueueRestingTime'
                    || $Name eq 'Kernel::System::Stats::Static::OTRSStatsResponseStatistic'
                );

            $Name =~ s/OTRSStats//;
            $XMLHash[0]{'otobo_stats'}[1]{ObjectModule}[1]{Content} = $Name;
        }

        # replace File name
        if ( exists $XMLHash[0]{'otobo_stats'}[1]{File} ) {
            my $Name = $XMLHash[0]{'otobo_stats'}[1]{File}[1]{Content};

            next KEY unless $Name;

            next KEY
                unless (
                    $Name eq 'OTRSStatsQueueWorkingTime'
                    || $Name eq 'OTRSStatsQueueRestingTime'
                    || $Name eq 'OTRSStatsResponseStatistic'
                );

            $Name =~ s/OTRSStats//;
            $XMLHash[0]{'otobo_stats'}[1]{File}[1]{Content} = $Name;
        }

        my $Success = $XMLObject->XMLHashUpdate(
            Type    => 'Stats',
            Key     => $Key,
            XMLHash => \@XMLHash,
        );
    }

    # rename (read, delete and write) installed.xml file
    {
        my $FileOld = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/var/stats/OTRSStats-ResponseStatistic.xml.installed';
        my $FileNew = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/var/stats/OTOBOStats-ResponseStatistic.xml.installed';
        if ( -e $FileOld ) {

            my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
            my $Content    = $MainObject->FileRead(
                Location => $FileOld,
            );

            $MainObject->FileDelete(
                Location => $FileOld,
            );

            my $Success = $MainObject->FileWrite(
                Content  => $Content,
                Location => $FileNew,
            );
        }
    }

    return 1;
}

1;
