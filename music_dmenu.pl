#!/usr/bin/perl
# See LICENSE file for copyright and license details.

use strict;
use warnings;

use Encode::Locale;
use IPC::Open2;
use List::Util qw(max);


###################
# Begin: userconfig
###################
my $home = "$ENV{HOME}";
# Use the quoted one in regexes.
my $home_q = qr($home);

# Specify (one or multiple) path(s) to search for music files.
my @paths = (
	"$home/Music",
);

# Specify (sub-)directories which you want to be considered as albums.
# If you select an album, all its files will be played consecutively
# in random order.
# (regex values)
my @albums = (
	$home_q . '\/Music\/example_album\/?',
);

# dmenu command
my $dmenu_cmd = "dmenu -fn DejaVuSansMono-12 -i -l 25 -nb \'#162f54\' -nf "
		. "\'#e2e2e2\' -sb \'#6574ff\' -sf \'#ffffff\'";
#my $dmenu_cmd = "wofi --dmenu -s ~/.config/wofi/monospaced.css";

# player for albums ...
my $player_album = "mpv";
# ... and single files
my $player = "mpv";

# arguments for $player playing albums
my @args_album = (
	"--player-operation-mode=pseudo-gui",
	"--profile=low-latency"
);
# arguments for $player playing single files
my @args = (
	@args_album,
	"--loop",
);

# Which separator do you use in filenames between the title of the music and
# the name of the artist?
# E.g. "T.N.T. (from Live at River Plate) - AC_DC.mp3" uses "space+dash+space
# as separator.
# Note that any additional whitespace around the title and the artist is
# removed.
# (string value)
my $separator = " - ";

# Determines the order in which <artist> and <title> are parsed from the
# filenames.
my $file_artist_first = 0;
# Determines the display order of <artist> and <title>.
my $display_artist_first = 0;

# We define our exceptions!
# The keys in the following hash are regular expressions for the filenames you
# want to play with a special command - this command (an array) is the value.
my %exceptions = (
	$home_q . '\/Music\/Song Title - Artist Name\.mp3' => 
	[ $player, @args, "--audio-channels=mono" ],
	$home_q . '\/Music\/Other Song Title - Artist Name' =>
	[ $player, @args, "--no-video" ],
);
#################
# End: userconfig
#################


# open dmenu, pipe the music list to it and read the selection the user made
sub dmenu {
	open2(my $in, my $out, $dmenu_cmd) or die $!;
	print($out map { Encode::encode(locale => $_) . "\n" } @_);
	close($out);
	my $selection = <$in>;
	close($in);

	exit 0 if (!$selection);
	chomp($selection);

	return Encode::decode(locale => $selection);
}

# Align the song/album descriptions.
# E.g.: convert
# "Song Title - Artist Name"
# to
# "Song Title [[:space:]]* Artist Name",
# using as many spaces as necessary to get everything aligned.
#
# The array given as argument (by reference) is modified in-place, so
# nothing is returned.
sub format_display_names {
	my @files = @{$_[0]};

	# Get the maximum length of the left display column.
	my $maxlen = get_maxlen_left_column(\@files);

	for (@files) {
		my ($file, $display_name) = @{$_};
		my ($artist, $title) = split_title_artist($display_name);

		if ($display_artist_first) {
			my $len = $maxlen - length($artist);
			$display_name = $artist . " " x $len . $title;
		} else {
			my $len = $maxlen - length($title);
			$display_name = $title . " " x $len . $artist;
		}

		$_->[1] = $display_name;
	}
}

sub get_filename {
	my @files = @{$_[0]};
	my $display_name = $_[1];

	my @file = grep { $_->[1] eq $display_name } @files;

	return @file ? $file[0]->[0] : '';
}

sub get_files {
	my @paths_l = @{$_[0]};
	my @files;

	for my $dir (@paths_l) {
		opendir(my $dh, $dir) or die $!;
		while (readdir($dh)) {
			next if ($_ =~ m/^\.\.?/);
			if (-d "$dir/$_") {
				push(@files, ["$dir/$_", preprocess_dirname($_)]);
			} else {
				push(@files, ["$dir/$_", preprocess_filename($_)]);
			}
		}
		closedir($dh);
	}

	# Sort using mtime.
	@files = sort { (stat $b->[0])[9] cmp (stat $a->[0])[9] } @files;

	return \@files;
}

# Get the maximum title length.
sub get_maxlen_left_column {
	my @files = @{$_[0]};

	my $index = $display_artist_first ? 0 : 1;

	my $len = max(map(length((split_title_artist($_->[1]))[$index]), @files));

	# Add some extra spaces between the columns.
	return $len + 8;
}

sub play_album {
	my $dir = $_[0];
	my @album;

	opendir(my $dh, $dir) or die $!;
	while (readdir($dh)) {
		next if (! -f "$dir/$_");
		push @album, "$dir/$_";
	}
	closedir($dh);

	for (@album) {
		play_file($_, 1);
	}

	exit 0;
}

sub play_file {
	my ($file, $wait) = @_;

	my @cmd = $wait ? ($player_album, @args_album) : ($player, @args);

	my @cmd_es = grep { $file =~ m/^${_}$/ } keys(%exceptions);
	if (@cmd_es) {
		# Use the last rule if there are more than one.
		@cmd = @{$exceptions{$cmd_es[-1]}};
	}

	# Indicate end of options and append filename.
	push(@cmd, "--", $file);

	my $pid = fork();
	die $! if (! defined($pid));
	if ($pid == 0) {
		# child
		exec { $cmd[0] } @cmd or die $!;
	}

	# parent
	if (!$wait) {
		exit 0;
	}

	while (wait() != -1) {
		exit if ($?);
	}
}

# Remove the filetype extension (.mp3, .wav, etc.) from the given
# filename.
sub preprocess_filename {
	my $name = shift;
	$name =~ s/\.[[:alnum:]]{3,4}$//;
	return Encode::decode(locale => $name);
}

# Append a slash to the name of a directory.
# If the directory name is composed of a title and an artist name,
# append the slash to the title.
sub preprocess_dirname {
	my ($artist, $title) = split_title_artist($_[0]);

	if ($artist eq '') {
		return $title . '/';
	} elsif ($file_artist_first) {
		return $artist . $separator . $title . '/';
	} else {
		return $title . '/' . $separator . $artist;
	}
}

# Split a given string into title and artist using $separator.
# Split on the first occurrence if $file_artist_first and on the last
# otherwise.
# Return (<artist>, <title>).
sub split_title_artist {
	my $i = $file_artist_first ? index($_[0], $separator) : rindex($_[0], $separator);

	if ($i == -1) {
		return ('', $_[0]);
	}

	my $first = trim(substr($_[0], 0, $i));
	my $second = trim(substr($_[0], $i + length($separator)));

	return $file_artist_first ? ($first, $second) : ($second, $first);
}

# Remove leading/trailing whitespace from a string.
sub trim {
	return $_[0] =~ s/^\s+|\s+$//gr;
}


while (1) {
	my $files = get_files(\@paths);
	format_display_names($files);

	my $selection = dmenu(map($_->[1], @{$files}));
	my $file = get_filename($files, $selection);

	exit 0 if ($file eq '');

	if (-d $file) {
		if (grep { $file =~ m/^${_}$/ } @albums) {
			play_album($file);
		} else {
			@paths = ($file);
		}
	} else {
		play_file($file);
	}
}
