package HyperV;

use strict;
use warnings;

use Data::Dumper;

# ----------------------------------------------------------------------------------------------------------------------

sub new {
    my ($class, $params) = @_;

    my $self;

    while (my ($k, $v) = each %{$params}) {
        $self->{ $k } = $v;
    }
    $self->{ 'timeout' } = 5 unless $self->{ 'timeout' };

    bless $self, $class;

    return $self;
}


# ----------------------------------------------------------------------------------------------------------------------

sub GetVHD {
    my ($self, $vm_name) = @_;

    my @result_hash_arr = ();
    my $cmd = 'Get-VM -VMName ' . $vm_name . ' | Select-Object VMId | Get-VHD';

    my $result = $self->execPowershell($cmd);

    my @result_arr = split('\n', $result);
    fixLongValues(\@result_arr);

    my $nn = -1;
    foreach my $row (@result_arr) {
        $nn ++  if $row =~ m/ComputerName/;
        next if $nn < 0;
        $result_hash_arr[$nn]->{ 'ComputerName' } = getValue($row, 'ComputerName')                  if ($row =~ m/ComputerName/);
        $result_hash_arr[$nn]->{ 'Path' } = getValue($row, 'Path')                                  if ($row =~ m/^Path/);
        $result_hash_arr[$nn]->{ 'VhdFormat' } = getValue($row, 'VhdFormat')                        if ($row =~ m/VhdFormat/);
        $result_hash_arr[$nn]->{ 'VhdType' } = getValue($row, 'VhdType')                            if ($row =~ m/VhdType/);
        $result_hash_arr[$nn]->{ 'FileSize' } = getValue($row, 'FileSize')                          if ($row =~ m/FileSize/);
        $result_hash_arr[$nn]->{ 'Size' } = getValue($row, 'Size')                                  if ($row =~ m/^Size/);
        $result_hash_arr[$nn]->{ 'MinimumSize' } = getValue($row, 'MinimumSize')                    if ($row =~ m/MinimumSize/);
        $result_hash_arr[$nn]->{ 'LogicalSectorSize' } = getValue($row, 'LogicalSectorSize')        if ($row =~ m/LogicalSectorSize/);
        $result_hash_arr[$nn]->{ 'PhysicalSectorSize' } = getValue($row, 'PhysicalSectorSize')      if ($row =~ m/PhysicalSectorSize/);
        $result_hash_arr[$nn]->{ 'BlockSize' } = getValue($row, 'BlockSize')                        if ($row =~ m/BlockSize/);
        $result_hash_arr[$nn]->{ 'ParentPath' } = getValue($row, 'ParentPath')                      if ($row =~ m/ParentPath/);
        $result_hash_arr[$nn]->{ 'FragmentationPercentage' } =
                    getValue($row, 'FragmentationPercentage')                                       if ($row =~ m/FragmentationPercentage/);
        $result_hash_arr[$nn]->{ 'Alignment' } = getValue($row, 'Alignment')                        if ($row =~ m/Alignment/);
        $result_hash_arr[$nn]->{ 'Attached' } = getValue($row, 'Attached')                          if ($row =~ m/Attached/);
        $result_hash_arr[$nn]->{ 'DiskNumber' } = getValue($row, 'DiskNumber')                      if ($row =~ m/DiskNumber/);
        $result_hash_arr[$nn]->{ 'IsDeleted' } = getValue($row, 'IsDeleted')                        if ($row =~ m/IsDeleted/);
        $result_hash_arr[$nn]->{ 'Number' } = getValue($row, 'Number')                              if ($row =~ m/^Number/);
    }

    return \@result_hash_arr;
}

# ----------------------------------------------------------------------------------------------------------------------

sub GetVMSummary {
    my ($self, $vm_name) = @_;

    my %result_hash = ();
    my $cmd = 'Get-VMSummary ' . $vm_name;

    my $result = $self->execPowershell($cmd);

    my @result_arr = split('\n', $result);

    foreach my $row (@result_arr) {
        $result_hash{ 'Host' } = getValue($row, 'Host')                          if ($row =~ m/Host/);
        $result_hash{ 'VMElementName' } = getValue($row, 'VMElementName')        if ($row =~ m/VMElementName/);
        $result_hash{ 'Notes' } = getValue($row, 'Notes')                        if ($row =~ m/Notes/);
        $result_hash{ 'CPULoad' } = getValue($row, 'CPULoad')                    if ($row =~ m/CPULoad/);
        $result_hash{ 'Name' } = getValue($row, 'Name')                          if ($row =~ m/Name/);
        $result_hash{ 'UptimeFormatted' } = getValue($row, 'UptimeFormatted')    if ($row =~ m/UptimeFormatted/);
        $result_hash{ 'EnabledState' } = getValue($row, 'EnabledState')          if ($row =~ m/EnabledState/);
        $result_hash{ 'Uptime' } = getValue($row, 'Uptime')                      if ($row =~ m/Uptime/);
        $result_hash{ 'MemoryUsage' } = getValue($row, 'MemoryUsage')            if ($row =~ m/MemoryUsage/);
        $result_hash{ 'FQDN' } = getValue($row, 'FQDN')                          if ($row =~ m/FQDN/);
        $result_hash{ 'CPUCount' } = getValue($row, 'CPUCount')                  if ($row =~ m/CPUCount/);
        $result_hash{ 'GuestOS' } = getValue($row, 'GuestOS')                    if ($row =~ m/GuestOS/);
        $result_hash{ 'CreationTime' } = getValue($row, 'CreationTime')          if ($row =~ m/CreationTime/);
        $result_hash{ 'ERROR' } = getValue($row, 'ERROR')                        if ($row =~ m/ERROR/);
    }

    return \%result_hash;
}

# ----------------------------------------------------------------------------------------------------------------------

sub execPowershell {
    my ($self, $cmd_args) = @_;

    my $cmd = 'winexe --user=' . $self->{ 'username' } . ' --password=' . $self->{ 'password' } . ' //'
                . $self->{ 'host' }
                . ' "powershell ' . $cmd_args . '" 2>&1';

    my $result = '';
    my $pid = 0;
    eval {
        local $SIG{ ALRM } = sub { die "alarm\n" };
        alarm $self->{ 'timeout' };
        $pid = open(PIPE, ${cmd} . ' |' );
        if ($pid != 0) {
            while (<PIPE>) {
                my ($line) = split('\n');
                $line .= "\n";
                $result .= $line;
            }
            close(PIPE);
        }
        else {
            $result = 'ERROR : Error running winexe.' . "\n";
            return $result;
        }
        alarm 0;
    };
    if ($@) {
        if ($@ eq "alarm\n") {
            `pkill -TERM -P ${pid}`;
            $result = 'ERROR : Timeout.' . "\n";
            return $result;
        }
    }

    $result =~ s/\r//g;

    return $result;
}

# ----------------------------------------------------------------------------------------------------------------------

sub getValue {
    my ($row, $name) = @_;

    $row =~ s/ : / \| /g;
    $row =~ s/: / \| /g;
    my ($tmp, $val) = split('\|', $row);
    $val =~ s/^\s+|\s+$//g  if $val;

    return $val;
}

# ----------------------------------------------------------------------------------------------------------------------

sub fixLongValues {
    my ($arr) = @_;

    for (my $ii=0; $ii<@{$arr}; $ii++)  {
        $arr->[$ii] =~ s/^\s+|\s+$//g;
        unless ($arr->[$ii] =~ m/:/) {
            $arr->[$ii - 1] .= $arr->[$ii];
            $arr->[$ii] = '';
        }
    }

    return;
}

1;
