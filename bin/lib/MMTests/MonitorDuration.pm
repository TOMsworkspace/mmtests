# MonitorDuration.pm
package MMTests::MonitorDuration;
use MMTests::SummariseSingleops;
our @ISA = qw(MMTests::SummariseSingleops);
use strict;

sub new() {
	my $class = shift;
	my $self = {
		_ModuleName  => "MonitorDuration",
		_DataType => DataTypes::DATA_TIME_SECONDS,
		_Opname	=> "Duration",
	};
	bless $self, $class;
	return $self;
}

sub extractReport($$$) {
	my ($self, $reportDir, $testBenchmark) = @_;
	my $file = "$reportDir/tests-timestamp";

	open(INPUT, $file) || die("Failed to open $file\n");
	while (<INPUT>) {
		if ($_ =~ /^time \:\: $testBenchmark (.*)/) {
			my $dummy;
			my ($user, $system, $elapsed);

			($user, $dummy,
			 $system, $dummy,
			 $elapsed, $dummy) = split(/\s/, $1);

			$self->addData("User", 0, $user );
			$self->addData("System", 0, $system );
			$self->addData("Elapsed", 0, $elapsed );
		}
	}
	close INPUT;
}

1;
