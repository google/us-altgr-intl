#!/usr/bin/perl
#
# Copyright (C) 2016 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is a quickly hacked-together script to export KCM files as HTML.
# Don't expect too much.

use strict;
use warnings;
use utf8;

# Shortened key names for display.
my %shorten = (
	ESCAPE => 'Esc',
	TAB => 'Tab',
	CAPS_LOCK => 'Caps',
	SHIFT_LEFT => 'Shift',
	SHIFT_RIGHT => 'Shift',
	CTRL_LEFT => 'Ctrl',
	CTRL_RIGHT => 'Ctrl',
	META_LEFT => 'Meta',
	META_RIGHT => 'Meta',
	ALT_LEFT => 'Alt',
	ALT_RIGHT => 'Alt',
	MENU => 'Menu',
	ENTER => 'Enter',
	SPACE => ' ',
	DEL => 'Backspace',
	LEFT => 'Left',
	RIGHT => 'Right',
	UP => 'Up',
	DOWN => 'Down',
);

my %keyboards = (
	pc => {
		rows => [
			[qw(GRAVE 1 2 3 4 5 6 7 8 9 0 MINUS EQUALS DEL)],
			[qw(TAB Q W E R T Y U I O P LEFT_BRACKET RIGHT_BRACKET BACKSLASH)],
			[qw(CAPS_LOCK A S D F G H J K L SEMICOLON APOSTROPHE ENTER)],
			[qw(SHIFT_LEFT Z X C V B N M COMMA PERIOD SLASH SHIFT_RIGHT)],
			[qw(CTRL_LEFT META_LEFT ALT_LEFT SPACE ALT_RIGHT META_RIGHT MENU CTRL_RIGHT)],
		],
		width => {
			_default => 4,

			DEL => 8,

			TAB => 6,
			BACKSLASH => 6,

			CAPS_LOCK => 7,
			ENTER => 9,

			SHIFT_LEFT => 9,
			SHIFT_RIGHT => 11,

			CTRL_LEFT => 6,
			META_LEFT => 5,
			ALT_LEFT => 5,
			SPACE => 23,
			ALT_RIGHT => 5,
			META_RIGHT => 5,
			MENU => 5,
			CTRL_RIGHT => 6,
		},
		height => {
			_default => 1,
		},
		modifiers => [
			[qw(shift ralt+shift)],
			[qw(base ralt)],
		],
		keycodes => {
			qw(
				41 GRAVE
				2 1
				3 2
				4 3
				5 4
				6 5
				7 6
				8 7
				9 8
				10 9
				11 0
				12 MINUS
				13 EQUALS
				14 DEL

				15 TAB
				16 Q
				17 W
				18 E
				19 R
				20 T
				21 Y
				22 U
				23 I
				24 O
				25 P
				26 LEFT_BRACKET
				27 RIGHT_BRACKET
				43 BACKSLASH

				58 CAPS_LOCK
				30 A
				31 S
				32 D
				33 F
				34 G
				35 H
				36 J
				37 K
				38 L
				39 SEMICOLON
				40 APOSTROPHE
				28 ENTER

				42 SHIFT_LEFT
				44 Z
				45 X
				46 C
				47 V
				48 B
				49 N
				50 M
				51 COMMA
				52 PERIOD
				53 SLASH
				54 SHIFT_RIGHT

				29 CTRL_LEFT
				125 META_LEFT
				56 ALT_LEFT
				57 SPACE
				100 ALT_RIGHT
				126 META_RIGHT
				139 MENU
				97 CTRL_RIGHT
			)
		},
	},
	dragon => {
		rows => [
			[qw(1 2 3 4 5 6 7 8 9 0 MINUS DEL)],
			[],
			[qw(TAB Q W E R T Y U I O P EQUALS ENTER)],
			[],
			[qw(CAPS_LOCK A S D F G H J K L SEMICOLON APOSTROPHE)],
			[],
			[qw(SHIFT_LEFT Z X C V B N M COMMA PERIOD SLASH SHIFT_RIGHT)],
			[],
			[qw(CTRL_LEFT ALT_LEFT SPACE ALT_RIGHT _empty_LEFT UP _empty_RIGHT)],
			[qw(LEFT DOWN RIGHT)],
		],
		width => {
			_default => 4,

			1 => 5,
			DEL => 5,

			TAB => 3,
			ENTER => 3,

			APOSTROPHE => 3,

			SHIFT_LEFT => 6,
			CTRL_LEFT => 7,
			ALT_LEFT => 7,
			SPACE => 20,
		},
		height => {
			_default => 2,

			ENTER => 4,

			_empty_LEFT => 1,
			UP => 1,
			_empty_RIGHT => 1,

			LEFT => 1,
			DOWN => 1,
			RIGHT => 1,
		},
		modifiers => [
			[qw(shift ralt+shift ctrl+ralt+shift)],
			[qw(base ralt ctrl+ralt)],
		],
		keycodes => {
			qw(
				1 ESCAPE
				2 1
				3 2
				4 3
				5 4
				6 5
				7 6
				8 7
				9 8
				10 9
				11 0
				12 MINUS
				14 DEL

				15 TAB
				16 Q
				17 W
				18 E
				19 R
				20 T
				21 Y
				22 U
				23 I
				24 O
				25 P
				13 EQUALS
				28 ENTER

				58 CAPS_LOCK
				30 A
				31 S
				32 D
				33 F
				34 G
				35 H
				36 J
				37 K
				38 L
				39 SEMICOLON
				40 APOSTROPHE

				42 SHIFT_LEFT
				44 Z
				45 X
				46 C
				47 V
				48 B
				49 N
				50 M
				51 COMMA
				52 PERIOD
				53 SLASH
				54 SHIFT_RIGHT

				29 CTRL_LEFT
				56 ALT_LEFT
				57 SPACE
				100 ALT_RIGHT
				103 UP

				105 LEFT
				108 DOWN
				106 RIGHT
			)
		},
	},
);

for (values %keyboards) {
	$_->{scancodes} = { reverse %{$_->{keycodes}} };
}

sub kcm_parse($$) {
	my ($keyboard, $fh) = @_;
	my %kcm = (
		keycodes => { %{$keyboard->{keycodes}} },
		modifiers => [ map { [@$_] } @{$keyboard->{modifiers}} ],
	);
	my (%modifier_cols, %modifier_rows);
	my (%unused_modifier_rows, %unused_modifier_cols);
	my %unused_modifiers;
	for my $row(0..@{$kcm{modifiers}}-1) {
		$unused_modifier_rows{$row} = 1;
		for my $col(0..@{$kcm{modifiers}[$row]}-1) {
			my $modifiers = $kcm{modifiers}[$row][$col];
			$unused_modifier_cols{$col} = 1;
			$unused_modifiers{$modifiers} = 1;
			$modifier_rows{$modifiers} = $row;
			$modifier_cols{$modifiers} = $col;
		}
	}
	my $key = undef;
	while (<$fh>) {
		chomp;
		s/\s+/ /g;
		s/^#.*//;
		s/ #.*//;
		s/ $//;
		s/^ //;
		if (/^$/) {
			next;
		} elsif (/^type (\w+)$/) {
			next;
		} elsif (/^map key (\d+) (\w+)$/) {
			$kcm{keycodes}{$1} = $2;
		} elsif (/^key (\w+) \{$/) {
			$key = $1;
		} elsif (/^\}$/) {
			undef $key;
		} elsif (/^([a-z+,\s]*): ?(?:replace (?<replace>.*)|'(?<string>.*)')$/) {
			my $value = $+{replace} // $+{string};
			for my $modifiers(split / ?, ?/, $1) {
				$modifiers = join '+', sort split /\+/, $modifiers;
				$value =~ s{
					\\(?:)
					(?:
						(?<literal>\W) |
						u(?<unicode>[0-9a-fA-F]{4})
					)
				}{
					$+{literal} // chr hex $+{unicode}
				}gex;

				$kcm{keysyms}{$key}{$modifiers} = $value;
				if (exists $modifier_rows{$modifiers}) {
					delete $unused_modifier_rows{$modifier_rows{$modifiers}};
					delete $unused_modifier_cols{$modifier_cols{$modifiers}};
					delete $unused_modifiers{$modifiers};
				} else {
					if ($modifiers =~ /label|capslock/) {
						# That's okay, we're not handling these.
					} else {
						warn "Unknown modifier combination: $modifiers";
					}
				}
			}
		} else {
			warn "Unsupported .kcm line: $_";
		}
	}
	for my $col(reverse sort keys %unused_modifier_cols) {
		for (@{$kcm{modifiers}}) {
			splice @$_, $col, 1, ();
		}
	}
	for my $row(reverse sort keys %unused_modifier_rows) {
		splice @{$kcm{modifiers}}, $row, 1, ();
	}
	for my $row(values @{$kcm{modifiers}}) {
		for (0..@$row-1) {
			$row->[$_] = ''
				if $unused_modifiers{$row->[$_]};
		}
	}
	return \%kcm;
}

sub kcm_header() {
	my $html = "";
	$html .= "<!DOCTYPE html>";
	$html .= "<title>Keyboard Layouts</title>";
	$html .= "<style type=\"text/css\">";
	$html .= <<'EOF';
table {
	width: 100%;
	height: 100%;
	table-layout: fixed;
}

td, th {
	text-align: center;
	vertical-align: middle;
}

div.item {
	page-break-inside: avoid;
}

table.keyboard {
	background-color: #888;
	font-family: monospace;
}

table.keyboard > tbody > tr > .label-only {
	background-color: #000;
	border: 2px outset #aaa;
	color: #ccc;
}

table.keyboard > tbody > tr > .with-alternatives {
	background-color: #000;
	border: 2px outset #aaa;
	color: #ccc;
}

table.keyboard > tbody > tr > .legend {
	color: #000;
}

table.key > tbody > tr > .label {
	color: #fff;
	font-weight: bold;
}

table.key > tbody > tr > .alternative {
	color: #ccc;
}

.non-ascii {
	color: red;
}
EOF
	$html .= "</style>";
	$html .= "<h1>Keyboard Layouts</h1>";
	return $html;
}

sub kcm_footer() {
	my $html = "";
	return $html;
}

sub escape($$) {
	my ($str, $non_ascii) = @_;
	$str =~ s/&/&amp;/g;
	$str =~ s/</&lt;/g;
	$str =~ s/>/&gt;/g;
	$str =~ s{(.)}{
		my $code = ord $1;
		if ($code < 0x20 || $code == 0x7f) {
			sprintf "\\x%02X", ord $_;
		} elsif ($code >= 0x80) {
			++$$non_ascii if defined $non_ascii;
			"<span class=\"non-ascii\">$1</span>"
		} else {
			$1;
		}
	}ge;
	return $str;
}

sub kcm_format($$$) {
	my ($keyboard, $title, $kcm) = @_;
	my $html = "";
	$html .= "<div class=\"item\">\n";
	$html .= "<h2>@{[escape $title, undef]}</h2>\n";
	$html .= "<table class=\"keyboard\"><tbody>\n";
	my $rowwidth = 0;
	my $have_non_ascii = 0;
	for my $key(@{$keyboard->{rows}[0]}) {
		my $size = $keyboard->{width}{$key} // $keyboard->{width}{_default};
		$rowwidth += $size;
	}
	my @rowwidths = ();
	for my $row(@{$keyboard->{rows}}) {
		$html .= "<tr>\n";
		for my $key(@$row) {
			my $size = $keyboard->{width}{$key} // $keyboard->{width}{_default};
			my $rowspan = $keyboard->{height}{$key} // $keyboard->{height}{_default};
			my $em = $size / $rowwidth;
			for (0..$rowspan-1) {
				$rowwidths[$_] += $size;
			}
			$html .= "<td rowspan=\"$rowspan\" colspan=\"$size\"";
			if ($key =~ /^_empty/) {
				$html .= " class=\"empty\">";
			} else {
				my $scancode = $keyboard->{scancodes}{$key};
				die "No scancode for $key"
					if not defined $scancode;
				my $keycode = $kcm->{keycodes}{$scancode};
				die "No keycode for $scancode"
					if not defined $keycode;
				my $keysyms = $kcm->{keysyms}{$keycode};
				if (defined $keysyms) {
					$html .= " class=\"with-alternatives\">";
					$html .= "<table class=\"key\"><tbody>";
					for my $modifier_row(@{$kcm->{modifiers}}) {
						$html .= "<tr>";
						for my $modifiers(@$modifier_row) {
							my $text = $keysyms->{$modifiers};
							my $label = $keysyms->{label};
							if (defined $text) {
								if ($text eq $label) {
									$text = $shorten{$text} // $text;
									$html .= "<th class=\"label\">@{[escape $text, \$have_non_ascii]}</th>";
								} else {
									$text = $shorten{$text} // $text;
									$html .= "<td class=\"alternative\">@{[escape $text, \$have_non_ascii]}</td>";
								}
							} else {
								$html .= "<td class=\"empty\"></td>";
							}
						}
						$html .= "</tr>";
					}
					$html .= "</tbody></table>";
				} else {
					my $label = $shorten{$keycode} // $keycode;
					$html .= " class=\"label-only\">";
					$html .= escape $label, \$have_non_ascii;
				}
			}
			$html .= "</td>\n";
		}
		my $width = shift @rowwidths;
		$html .= "</tr>\n";
		if (defined $rowwidth && $width != $rowwidth) {
			warn "Nonequal widths (got $width, want $rowwidth)";
		}
	}
	$html .= "<tr>\n";
	$html .= "<th colspan=\"$rowwidth\" style=\"width: 100%;\" class=\"legend\">";
	$html .= "Legend:";
	$html .= "<table class=\"key\"><tbody>";
	for my $modifier_row(@{$kcm->{modifiers}}) {
		$html .= "<tr>";
		for my $modifiers(@$modifier_row) {
			if ($modifiers eq 'base') {
				$html .= "<td class=\"label\">@{[escape $modifiers, undef]}</td>";
			} else {
				$html .= "<td class=\"alternative\">@{[escape $modifiers, undef]}</td>";
			}
		}
		$html .= "</tr>";
	}
	$html .= "</tbody></table>\n";
	if ($have_non_ascii != 0) {
		$html .= "<span class=\"non-ascii\">Non-ASCII</span>";
	}
	$html .= "</th>\n";
	$html .= "</tr>\n";
	$html .= "</tbody></table>\n";
	$html .= "</div>\n";
	return $html;
}

my $kbd = $keyboards{pc};

binmode STDOUT, ':utf8';
print kcm_header();
for (@ARGV) {
	if ($_ eq '--dragon') {
		$kbd = $keyboards{dragon};
	} elsif ($_ eq '--pc') {
		$kbd = $keyboards{pc};
	} else {
		my $title = $_;
		$title =~ s/.*\///;
		open my $fh, '<', $_
			or die "Opening $_: $!";
		my $kcm = kcm_parse $kbd, $fh;
		print kcm_format($kbd, $title, $kcm);
		close $fh;
	}
}
print kcm_footer();
