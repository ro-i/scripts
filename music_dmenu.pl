#!/usr/bin/perl
# See LICENSE file for copyright and license details.

use strict;
use warnings;

use Encode::Locale;
use IPC::Open2;
use List::Util qw(max);
use Sort::Naturally qw(ncmp nsort);
use Text::CharWidth qw(mbswidth);


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
# If you select a file in an album, it will played together with all
# of the following files consecutively. (In an album, all files are
# sorted in natural sort order.)
# (regex values)
my @albums = (
    $home_q . '\/Music\/example_album\/',
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
# Sort order. Use file modification time by default.
# If disabled, sort according last file access time.
# Can be switched during runtime by "selecting" the (non-existant) value
# "//" in dmenu.
# Note that albums are always played according to natural sorting of the
# file names.
my $sort_mtime = 1;

# We define our exceptions!
# The keys in the following hash are regular expressions for the filenames you
# want to play with a special command - this command (an array) is the value.
# Note that this is discarded when playing multiple files in an album.
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
    my $maxlen = get_max_display_len_left_column(\@files);

    for (@files) {
        my ($file, $display_name) = @{$_};
        my ($artist, $title) = split_title_artist($display_name);

        if ($display_artist_first) {
            my $len = $maxlen - mbswidth($artist);
            $display_name = $artist . " " x $len . $title;
        } else {
            my $len = $maxlen - mbswidth($title);
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
    my $files = $_[1];

    for my $dir (@paths_l) {
        opendir(my $dh, $dir) or die $!;
        while (readdir($dh)) {
            next if ($_ =~ m/^\.\.?/);
            if (-d "$dir/$_") {
                push(@{$files}, ["$dir/$_", preprocess_dirname($_)]);
            } else {
                push(@{$files}, ["$dir/$_", preprocess_filename($_)]);
            }
        }
        closedir($dh);
    }

    if (paths_is_album(\@paths_l)) {
        # Natural sort.
        @{$files} = sort { ncmp($a->[0], $b->[0]) } @{$files};
    } else {
        # Sort using mtime if $sort_mtime, otherwise use atime.
        my $stat_index = $sort_mtime ? 9 : 8;
        @{$files} = sort { (stat $b->[0])[$stat_index] cmp (stat $a->[0])[$stat_index] } @{$files};
    }
}

# Get the maximum title length.
sub get_max_display_len_left_column {
    my @files = @{$_[0]};

    my $index = $display_artist_first ? 0 : 1;

    my $len = max(map(mbswidth((split_title_artist($_->[1]))[$index]), @files));

    # Add some extra spaces between the columns.
    return (defined($len) ? $len : 0) + 8;
}

# Take the current path list and check whether we are operating in an
# album at the moment. (Consider subdirectories!)
sub paths_is_album {
    my @paths_l = @{$_[0]};
    my $path = $paths_l[0] . "/";
    return (length(@paths_l == 1) and (grep { $path =~ m/^${_}/ } @albums));
}

# Play the given file and all following files in this album.
sub play_album {
    my ($file, $dir) = @_;
    my $skip = 1;
    my @album;
    my @to_play;

    opendir(my $dh, $dir) or die $!;
    while (readdir($dh)) {
        next if (! -f "$dir/$_");
        push(@album, "$dir/$_");
    }
    closedir($dh);

    # Sort the filenames using natural sort.
    for (nsort(@album)) {
        if ($skip and $_ eq $file) {
            $skip = 0;
        }
        next if ($skip);
        push(@to_play, $_);
    }

    play_files(@to_play);

    exit 0;
}

sub play_files {
    my @files = @_;
    my $len = $#files + 1;

    return if (! $len);

    my @cmd = $len > 1 ? ($player_album, @args_album) : ($player, @args);

    if ($len == 1) {
        my @cmd_es = grep { $files[0] =~ m/^${_}$/ } keys(%exceptions);
        if (@cmd_es) {
            # Use the last rule if there are more than one.
            @cmd = @{$exceptions{$cmd_es[-1]}};
        }
    }

    # Indicate end of options and append filename.
    push(@cmd, "--", @files);

    my $pid = fork();
    die $! if (! defined($pid));
    if ($pid == 0) {
        # child
        exec { $cmd[0] } @cmd or die $!;
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
    my $second = trim(substr($_[0], $i + mbswidth($separator)));

    return $file_artist_first ? ($first, $second) : ($second, $first);
}

# Remove leading/trailing whitespace from a string.
sub trim {
    return $_[0] =~ s/^\s+|\s+$//gr;
}

my $play_rand_file = 0;

if (scalar(@ARGV) == 1) {
    if ($ARGV[0] eq "rand") {
        $play_rand_file = 1;
    } else {
        die $ARGV[0] . ": unrecognized argument\n";
    }
} elsif (scalar(@ARGV) > 0) {
    die "error: invalid number of arguments\n";
}

while (1) {
    my @files = ();

    get_files(\@paths, \@files);
    if (! paths_is_album(\@paths)) {
        format_display_names(\@files);
    }

    my $selection;
    if (! $play_rand_file) {
        $selection = dmenu(map($_->[1], @files));
        if ($selection eq '//') {
            $sort_mtime = ! $sort_mtime;
            next;
        } elsif ($selection eq '//r') {
            $play_rand_file = 1;
        }
    }
    if ($play_rand_file) {
        $selection = $files[rand(grep { ! -d $_ } @files)]->[1]
    }

    my $file = get_filename(\@files, $selection);
    exit 0 if ($file eq '');

    if (-d $file) {
        @paths = ($file);
    } elsif (paths_is_album(\@paths)) {
        play_album($file, $paths[0]);
    } else {
        play_files(($file));
        exit 0;
    }
}
