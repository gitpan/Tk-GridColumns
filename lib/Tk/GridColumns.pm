package Tk::GridColumns;

# PRAGMAS
# -------
use strict;
use warnings 'all';

# MODULES
# -------
use Tk;
use Tk::Button;
use Tk::Frame;
use Tk::Pane;
use Tk::ROText;

# GLOBALS
# -------
# version
$Tk::GridColumns::VERSION = '0.07';

# package local
my $DEBUG = 100;	# debuglevel
my $ID    =   0;	# id for the pane window

# METHODS
# -------
#
# get_version() - Get the module's version
#
sub get_version    ($ ) { $Tk::GridColumns::VERSION }

#
# debuglevel get-/setter
#
sub set_debuglevel ($$) { $DEBUG = pop }
sub get_debuglevel ($ ) { $DEBUG       }

#
# generate default header command ( sort the grid )
#
sub generate_header_cmd ($) {
	sub ($$) {
		my( $self, $x ) = @_;				# pick parameters

		my $data = $self->get_data;			# get data
		my $head = $self->get_header;			# get header

		print __PACKAGE__ . " :: Sort after column '$x'\n" if $DEBUG;

		return if @$data < 2;				# dont sort less than 2 elements

		print __PACKAGE__ . " ::  -algorithm: '$head->[$x]->[1]'\n" if $DEBUG > 25;

		# sort after column $x
		my $start = time();
		my @tmp   = sort  {
			### EVIL - FIND ANOTHER SOLUTION ###
			my @t = ( $a, $b );
			( $a, $b ) = ( $a->[$x], $b->[$x] );
			my $t = eval $head->[$x]->[1];
			( $a, $b ) = @t;
			$t
		} (@$data);

		print __PACKAGE__ . " ::  -time: '". ( time() - $start ) ."' secs\n" if $DEBUG > 50;

		@tmp    = $head->[$x]->[2] ? reverse @tmp	# reverse order
					   :         @tmp;	# keep order

		$head->[$x]->[2] = !$head->[$x]->[2];		# reverse reverse-flag
		@$data = @tmp;					# assign data

		print "\n" if $DEBUG;

		$self->refresh_items;				# refresh display
	} # sub
} # generate_header_cmd

#
# generate default item draw command ( use a Tk::ROText to display the data )
#
sub generate_item_draw_cmd ($) {
	sub ($$) {
		my( $self, $item ) = @_;			# pick parameters

		my $frame = $self->get_frame;			# get frame

		my $width = length( $item );			# get item width
		print __PACKAGE__ . " ::   -width: '$width'\n" if $DEBUG > 75;

		# create item
		my $w = $frame -> Scrolled(
			ROText		=>
			-scrollbars	=> $self->get_opt('-item_scrollbars'),
			-font		=> $self->get_opt('-item_font'),
			-background	=> $self->get_opt('-item_background'),
			-bd		=> $self->get_opt('-item_bd'),
			-relief		=> $self->get_opt('-item_relief'),
			-width		=> $width < 30 ? $width : 30,	# don't let it take all the space
			-height		=> 2,				# dito
		);

		$w -> insert(					# insert the data
			'end',
			$item,
		);

		return $w;					# return created widget
	} # sub
} # generate_item_draw_cmd

#
# constructor
#
sub new ($$;) {
	my( $class, $top, %opt ) = @_;		# pick parameters
	$class = ref($class) || $class;		# dual-constructor

	print __PACKAGE__ . " :: Create new object of class '$class'\n\n" if $DEBUG;

	# create obejct
	my $obj = {
		frame	=>  0,					# predefine, store it later
		head	=> [],					# header section
		data	=> [],					# data section
		grid	=> {},					# gridded widgets
		weight	=> {},					# weigth columns
		opt	=> {					# widget option defaults
			-scrollbars	 => 'ose',
			-relief		 => 'sunken',
			-bd		 => 2,
			-background	 => 'white',
			-header_font	 => '{Arial} 10 {bold}',
			-header_cmd	 => $class->generate_header_cmd,	# generate default header command ( sort the grid )
			-item_font	 => '{Arial} 10 {normal}',
			-item_scrollbars => 'osoe',
			-item_relief	 => 'sunken',
			-item_bd	 => 2,
			-item_padx	 => 1,
			-item_pady	 => 1,
			-item_background => Tk::NORMAL_BG,			# standard Tk background color
			-item_draw_cmd	 => $class->generate_item_draw_cmd,	# generate default item draw command ( use a Tk::ROText to display the data )
		},
	};
	bless $obj, $class;						# bless the reference

	$obj->set_opt( %opt );						# set user options

	# create and pack Pane
	my $pane = $top -> Scrolled(
		Pane => Name	=> __PACKAGE__ . $ID++,			# unique ID
		-scrollbars	=> $obj->get_opt('-scrollbars'),	# scrollbar locations
		-relief		=> $obj->get_opt('-relief'),		# border-type
		-bd		=> $obj->get_opt('-bd'),		# border-width
		-gridded	=> 'xy',				# fill the whole $top
		-sticky		=> 'nsew',				# fill the whole $top
		-background	=> $obj->get_opt('-background'),	# background-color
	) -> pack(
		-fill		=> 'both',				# fill the whole $top
		-expand		=> 1,					# fill the whole $top
	) -> Subwidget( 'scrolled' );					# get the pane from the Scrolled

	$obj->{frame} = $pane -> Subwidget( 'frame' );			# get the frame from the pane

	return $obj;							# return object
} # new

#
# set_opt() - Set widget options
#
sub set_opt ($;) {
	my( $self, %opt ) = @_;				# pick parameters

	print __PACKAGE__ . " :: Set options\n" if $DEBUG;
	if ( $DEBUG > 25 ) {
		foreach my $key ( keys %opt ) {
			print __PACKAGE__ . " ::  -opt: '$key' => '$opt{$key}'\n";
		} # foreach
	}
	print "\n" if $DEBUG;

	%{$self->{opt}} = ( %{$self->{opt}}, %opt );	# write options

	return $self;					# return object
} # set_opt

#
# get_opt() - Get widget options
#
sub get_opt ($;) {
	my( $self, @opt ) = @_;				# pick parameters

	if ( $DEBUG > 50 )
	{
		print __PACKAGE__ . " :: Get options\n";
		print __PACKAGE__.qq( ::  -opt: '@{[join"', '",@opt]}'\n);
		print "\n";
	} # if

	return @{$self->{opt}}{@opt};			# return option values
} # get_opt

#
# set_header() - Set the header section ( buttons and sort algorithms )
#
sub set_header ($$) {
	my( $self, $head ) = @_;			# pick parameters

	print __PACKAGE__ . " :: Set header\n" if $DEBUG;

	if ( $DEBUG > 25 ) {
		print __PACKAGE__ . " ::  -header dump:\n";

		if ( require Data::Dumper ) {
			print Data::Dumper::Dumper( $head ), "\n";
		}
		else {
			print __PACKAGE__ . " ::  !can't dump without Data::Dumper installed!\n";
		}
	}
	print "\n" if $DEBUG;

	$self->{head} = $head;				# assign the new header

	return $self;					# return object
} # set_header

#
# set_data() - Set the data section ( row's elements )
#
sub set_data ($$) {
	my( $self, $data ) = @_;	# pick parameters

	print __PACKAGE__ . " :: Set data\n" if $DEBUG;

	if ( $DEBUG > 25 ) {
		print __PACKAGE__ . " ::  -data dump:\n";

		if ( require Data::Dumper ) {
			print Data::Dumper::Dumper( $data ), "\n";
		}
		else {
			print __PACKAGE__ . " ::  !can't dump without Data::Dumper installed!\n";
		}
	}
	print "\n" if $DEBUG;

	$self->{data} = $data;		# assign data section

	return $self;			# return object
} # set_data

#
# set_weight() - Set the columns weight
#
sub set_weight ($$@) {
	my( $self, $mode, @columns ) = @_;		# pick parameters

	print __PACKAGE__ . " :: Set weight\n" if $DEBUG;
	print __PACKAGE__ . " ::  -mode: '$mode'\n" if $DEBUG > 25;
	print __PACKAGE__.qq( ::  -cols: '@{[join"', '",@columns]}'\n) if $DEBUG > 25;

	foreach my $c ( @columns ) {			 # iterate over @columns
		$mode ?        $self->{weight}->{$c} = 1 # set column's weight to 1
		      : delete $self->{weight}->{$c} ;	 # delete this column from the weight list
	} # foreach

	print "\n" if $DEBUG;

	return $self;					# return object
} # set_weight

#
# getter
#
sub get_header ($) { $_[0]->{ head } }
sub get_data   ($) { $_[0]->{ data } }
sub get_weight ($) { $_[0]->{weight} }
sub get_grid   ($) { $_[0]->{ grid } }
sub get_frame  ($) { $_[0]->{frame } }

#
# del_header() - Delete the header
#
sub del_header ($) {
	my( $self ) = @_;				# pick object

	print __PACKAGE__ . " :: Delete header\n" if $DEBUG;

	my $grid = $self->get_grid;			# get grid

	foreach my $n ( keys %$grid ) {			# iterate over the grid
		if ( $n =~ /^HEAD/ ) {			# search leading 'HEAD'
			print __PACKAGE__ . " ::  -item: '$n'\n" if $DEBUG > 75;

			       $grid->{$n}->destroy;	# destroy the widget
			delete $grid->{$n};		# delete it from the widget-hash
		} # if
	} # foreach

	print "\n" if $DEBUG;

	return $self;					# return object
} # del_header

#
# del_items() - Delete the items
#
sub del_items ($) {
	my( $self ) = @_;				# pick object

	print __PACKAGE__ . " :: Delete items\n" if $DEBUG;

	my $grid = $self->get_grid;			# get grid

	foreach my $n ( keys %$grid ) {			# iterate over the grid
		if ( $n =~ /^ITEM/ ) {			# search leading 'ITEM'
			print __PACKAGE__ . " ::  -item: '$n'\n" if $DEBUG > 75;

			       $grid->{$n}->destroy;	# destroy the widget
			delete $grid->{$n};		# delete it from the widget-hash
		} # if
	} # foreach

	print "\n" if $DEBUG;

	return $self;					# return object
} # del_items

#
# draw_header() - Draw the header
#
sub draw_header ($) {
	my( $self ) = @_;				# pick object

	print __PACKAGE__ . " :: Draw header\n" if $DEBUG;

	my $head  = $self->get_header;			# get header
	my $frame = $self->get_frame;			# get frame
	my $data  = $self->get_data;			# get data
	my $grid  = $self->get_grid;			# get grid

	for my $x ( 0 .. $#{$head} ) {
		print __PACKAGE__ . " ::  -name: '$head->[$x]->[0]'\n" if $DEBUG > 25;

		$grid->{'HEAD'.$x} = $frame -> Button(	# create header
			-text	 => $head->[$x]->[0],
			-font	 => $self->get_opt('-header_font'),
			-command => $self->get_opt('-header_cmd'),
		) -> grid(				# position the widget
			-row	=> 0,			# keep row because it's an header
			-column	=> $x,
			-sticky	=> 'ew',		# stretch horizontally
		);
	} # for $x

	print "\n" if $DEBUG;

	return $self;					# return object
} # draw_header

#
# draw_items() - Draw the items
#
sub draw_items ($) {
	my( $self ) = @_;					# pick object

	print __PACKAGE__ . " :: Draw items\n" if $DEBUG;

	my $frame = $self->get_frame;				# get frame
	my $data  = $self->get_data;				# get data
	my $grid  = $self->get_grid;				# get grid
	my $head  = $self->get_header;				# get header

	for my $y ( 0 .. $#{$data} ) {				# iterate over rows
		for my $x ( 0 .. $#{$data->[$y]} ) {		# iterate over columns
			my $item  = "" . $data->[$y]->[$x];	# get item

			print __PACKAGE__ . " ::  -item: '$item'\n" if $DEBUG > 25;
			print __PACKAGE__ . " ::   -coords: '$x' : '$y' ( row : col )\n" if $DEBUG > 50;

			$grid->{'ITEM'.$x.'.'.$y} = $self->get_opt('-item_draw_cmd');	# create item
			$grid->{'ITEM'.$x.'.'.$y} -> grid(				# position item
				-row		=> $y+1,
				-column		=> $x,
				-sticky		=> 'nsew',				# let it stretch if other items in the actual column are bigger
				-padx		=> $self->get_opt('-item_padx'),
				-pady		=> $self->get_opt('-item_pady'),
			);
		} # for $x
	} # for $y

	print __PACKAGE__ . " ::  create extra frame to fill the whole window\n" if $DEBUG;

	# create extra cell at the bottom to fill the whole window
	$grid->{'ITEM.EX'} = $frame -> Frame(
		-relief	=> 'flat',
		-bd	=> 0,
		-background => 'white',
	) -> grid(
		-row	=> 1+@$data,
		-column => 0,
		-columnspan => 0+@$head,
		-sticky	=> 'nsew',
	);

	# stretch columns
	print __PACKAGE__ . " ::  stretch columns and extra frame\n" if $DEBUG;

	$frame -> gridColumnconfigure(
		$_,
		-weight => $self->{weight}->{$_+1}
			|| 0,
	) for 0 .. $#{$head};
	$frame -> gridRowconfigure( 1+@$data, -weight => 1 );

	print "\n" if $DEBUG;

	return $self;					# return object
} # draw_items

#
# refresh routines
#
sub refresh_items  ($) { $_[0]->del_items->draw_items         }
sub refresh_header ($) { $_[0]->del_header->draw_header       }
sub refresh        ($) { $_[0]->refresh_header->refresh_items }

# TO GAIN MORE PERFORMANCE: REFERSH ONLY THE CHANGED PART OF THE GRID HERE!!!
#
# add_row() - Add a new data row
#
sub add_row ($@) {
	my( $self, @row ) = @_;				# pick parameters

	print __PACKAGE__ . " :: Add data row\n" if $DEBUG;
	print __PACKAGE__.qq( ::  -items: '@{[join"', '",@row]}'\n) if $DEBUG > 25;

	push @{ $self->{data} }, \@row;			# add row

	print "\n" if $DEBUG;

	return $self;					# return object
} # add_row

#
# get_item() - get the widget gridded at position x, y
#
sub get_item($$$) {
	my( $self, $x, $y ) = @_;				# pick prameters

	print __PACKAGE__ . " :: Get item\n" if $DEBUG;
	print __PACKAGE__ . " ::  -coords: '$y' : '$x' ( row : col )\n" if $DEBUG > 25;
	print "\n" if $DEBUG;

	my $grid = $self->get_grid;				# get grid

	return undef unless exists $grid->{'ITEM'.$x.'.'.$y};	# return undef if the item doesn't exists
	return $grid->{'ITEM'.$x.'.'.$y};			# return the item
} # get_item

#
# get_head() - get the widget gridded at position x, 0
#
sub get_head ($$) {
	my( $self, $x ) = @_;					# pick parameters

	print __PACKAGE__ . " :: Get caption\n" if $DEBUG;
	print __PACKAGE__ . " ::  -coords: '0' : '$x' ( row : col )\n" if $DEBUG > 25;
	print "\n" if $DEBUG;

	my $grid = $self->get_grid;				# get grid

	return undef unless exists $grid->{'HEAD'.$x};		# return undef if the item doesn't exists
	return $grid->{'HEAD'.$x};				# return the item
} # get_head

#
# may show debug information if the object gets destroyed
#
sub DESTROY {
	print __PACKAGE__ . " :: Destroy object\n\n" if $DEBUG;
} # DESTROY

1;

__END__

=pod

=head1 NAME

Tk::GridColumns - Columns widget for Tk

=head1 SYNOPSIS

	use Tk::GridColumns;					  # load the module

	# to create a new Tk::GridColumns widget, use the following syntax,
	# all options are optional, each default is shown here:
	my $gc = new Tk::GridColumns (			  	  # create a Tk::GridColumns widget
		$top,						  # the frame/window to put it in
		-scrollbars		=> 'ose',		  # change the scrollbars for the Pane
		-relief			=> 'sunken',		  # change the relief for the Pane
		-bd			=> 2,			  # change the borderwidth for the Pane
		-background		=> 'white',		  # change the background for the Pane
		-header_font		=> '{Arial} 10 {bold}',	  # change the header font
		-header_cmd		=> Tk::GridColumns->generate_header_cmd,	# change the header command
		-item_scrollbars	=> 'osoe',		  # change the scrollbars for each item
		-item_relief		=> 'sunken',		  # change the relief for each item
		-item_bd		=> 2,			  # change the borderwidth for each item
		-item_background	=> Tk::NORMAL_BG,	  # change the background for each item
		-item_font		=> '{Arial} 10 {normal}', # change the font for each item
		-item_padx		=> 1,			  # change the x-padding for each item
		-item_pady		=> 1,			  # change the y-padding for each item
		-item_draw_cmd		=> Tk::GridColumns->generate_item_draw_cmd,	# change the item draw command
	);

	$gc->generate_header_cmd;	# returns a sub to sort the grid, parameters are: object, column to sort after
	$gc->generate_item_draw_cmd;	# returns a sub to create a Tk::ROText widget with content and restricted width and height, paraneters are: object, content

	$gc->set_opt( %opt  );		# change options
	$gc->get_opt( @keys );		# get option values

	$gc->set_data( $data );		# set grid data
	$gc->get_data;			# get grid data
	$gc->set_header( $head );	# set header data
	$gc->get_header;		# get header data
	$gc->set_weight( $m, @cols );	# set column's ( @cols ) weight to $m
	$gc->get_weight;		# get the actual weight for some columns, unspecified columns have the weight 0

	$gc->get_frame;			# get the frame the items and the header is gridded on
	$gc->get_grid;			# get the widget hash, all displayed widgets can get found in this hash

	$gc->add_row( @cols );		# add a data row to the GC ( after this operation you should refresh the items )
	$gc->get_item( $x, $y );	# get the widget gridded at position $x, $y
	$gc->get_head( $x );		# get the caption gridded at position $x, 0

	$gc->refresh_header;		# refresh the header
	$gc->refresh_items;		# refresh the items
	$gc->refresh;			# refresh header and items

	$gc->del_header;		# delete the actual header ( after this operation you should refresh the header )
	$gc->del_items;			# delete the actual items ( after this operation you should refresh the items )

	$gc->draw_header;		# draw the actual header ( after this operation you should refresh the header )
	$gc->draw_items;		# draw the actual items ( after this operation you should refresh the items )

	# the following is NOT supported
	#my $gc = $top -> GridColumns( %opt );	# this is NOT supported

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head2 Header Command

As you can see in the synopsis you can specify your own '-header_cmd'.
This command will get 2 parameters on call, the object and the column the caption that has been clicked is gridded in.
If you need extra data from the user, you can use the header to get it:

	$gc->set_opt(
		-header_cmd => sub {
			my( $self, $x ) = @_;			# pick object and column

			my $capt  = $self->get_header->[$x];	# get caption at column $x
			my @extra = @{$capt->[1..$#{$capt}]};	# get the extra infos
		},
	);

If you want to get the old command back use the generate_header_cmd() method, which will return the default sub:

	$gc->set_opt(
		-header_cmd => $gc->generate_header_cmd,
	);

=head2 Item draw command

As you can see in the synopsis you can specify your own '-item_draw_cmd'.
This command will get 2 parameters on call, the object and the item to display.
Inside this sub you have to create and return a Tk widget which displays the item, but don't pack() ( or grid() or place() or form() ) it.
The returned widget will get gridded to the right position by the module.

If you want to get the old command back use the generate_item_draw_cmd() method, which will return the default sub:

	$gc->set_opt(
		-item_draw_cmd => $gc->generate_item_draw_cmd,
	);

For an example of such a command, please look for the generate_item_draw_cmd() subroutine in hte module's code.

=head1 SEE ALSO

Tk::Columns, Tk::MListbox, Tk::Table

=head1 AUTHOR

Matthias Wienand, E<lt>matthias.wienand@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Standard Perl license.

Copyright (C) 2008 by Matthias Wienand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
