# ExtractPgbenchstalls.pm
package MMTests::ExtractPgbenchstalls;
use MMTests::SummariseSingleops;
use MMTests::Stat;
our @ISA = qw(MMTests::SummariseSingleops);
use strict;

sub initialise() {
	my ($self, $subHeading) = @_;
	$self->{_ModuleName} = "ExtractPgbenchstalls";
	$self->{_DataType}   = DataTypes::DATA_TIME_SECONDS;
	$self->{_PlotType}   = "client-errorlines";
	$self->{_PlotXaxis}  = "Clients";
	$self->{_FieldLength} = 12;
	$self->{_DefaultPlot} = "1";

	$self->SUPER::initialise($subHeading);
}

sub extractReport() {
	my ($self, $reportDir) = @_;
	my $stallStart = 0;
	my @clients = $self->discover_scaling_parameters($reportDir, "pgbench-", ".log");

	# Extract per-client transaction information
	foreach my $client (@clients) {
		my $sample = 0;
		my $stallStart = 0;
		my $stallThreshold = 0;
		my @values;

		my $file = "$reportDir/pgbench-transactions-$client.log.gz";
		open(INPUT, "gunzip -c $file|") || die("Failed to open $file\n");
		while (<INPUT>) {
			my @elements = split(/\s+/, $_);
			push @values, $elements[1];
			my $nrTransactions = $elements[1];
		}
		close(INPUT);
		$stallThreshold = int (calc_amean(\@values) / 4);
		$#values = -1;

		open(INPUT, $file) || die("Failed to open $file\n");
		while (<INPUT>) {
			# time num_of_transactions latency_sum latency_2_sum min_latency max_latency
			my @elements = split(/\s+/, $_);
			my $nrTransactions = $elements[1];
			$sample++;
			if ($nrTransactions < $stallThreshold) {
				if ($stallStart == 0) {
					$stallStart = $elements[0];
				}
			} else {
				if ($stallStart) {
					my $stallDuration = $elements[0] - $stallStart;
					$stallStart = 0;
					push @values, $stallDuration;
				}
			}
		}
		close INPUT;

		$self->addData("NrStalls-$client", 0, $#values + 1);
		if ($#values >= 0) {
			$self->addData("MinStall-$client", 0, calc_min(\@values));
			$self->addData("AvgStall-$client", 0, calc_amean(\@values));
			$self->addData("MaxStall-$client", 0, calc_max(\@values));
			$self->addData("TotStall-$client", 0, calc_sum(\@values));
		} else {
			$self->addData("MinStall-$client", 0, 0);
			$self->addData("AvgStall-$client", 0, 0);
			$self->addData("MaxStall-$client", 0, 0);
			$self->addData("TotStall-$client", 0, 0);
		}
	}
}

1;
