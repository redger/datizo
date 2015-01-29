module datizo;

import std.stdio;
import std.string;

alias ubyte  uint08;
alias ushort uint16;
alias uint   uint32;
alias ulong  uint64;

alias byte   int08;
alias short  int16;
alias int    int32;
alias long   int64;

struct Date {
	int64 year  = 1;
	int08 month = 1;
	int08 day   = 1;

	string toString() {
		return format("%04d-%02d-%02d", year, month, day);
	}
}

struct Time {
	int08 hour       = 0;
	int08 minute     = 0;
	int08 second     = 0;
	int32 nanosecond = 0;

	string toString() {
		return format("%02d:%02d:%02d.%09d", hour, minute, second, nanosecond);
	}
}

struct Zone {
	int08 sign   = 1;
	Time  offset = Time();

	string toString() {
		return "-+"[sign >= 0]~format("%02d:%02d", offset.hour, offset.minute);
	}
}

struct Datizo {
	Date date = Date();
	Time time = Time();
	Zone zone = Zone();

	string toString() {
		return date.toString~'T'~time.toString~zone.toString;
	}
}


void main() {

	// simple test
	Datizo datizo = Datizo();
	writeln( datizo.toString );

}