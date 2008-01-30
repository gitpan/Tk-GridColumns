# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-GridColumns.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Tk::GridColumns') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Tk;

my $mw = tkinit;

my $gc = Tk::GridColumns->new( $mw );
isa_ok($gc,'Tk::GridColumns');

can_ok(
	$gc => qw/
		get_version
		get_debuglevel
		set_debuglevel
		new
		get_opt
		set_opt
		get_header
		set_header
		get_data
		set_data
		add_row
		get_weight
		set_weight
		get_grid
		get_frame
		del_header
		del_items
		draw_header
		draw_items
		refresh_header
		refresh_items
		refresh
	/,
);