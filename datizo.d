/++
-----------===[   DATIZO  (DAte TIme ZOne)   ]===-----------
  _____     ______     ______   __     ______     ______
 /\  __-.  /\  __ \   /\__  _\ /\ \   /\___  \   /\  __ \
 \ \ \/\ \ \ \  __ \  \/_/\ \/ \ \ \  \/_/  /__  \ \ \/\ \
  \ \____-  \ \_\ \_\    \ \_\  \ \_\   /\_____\  \ \_____\
   \/____/   \/_/\/_/     \/_/   \/_/   \/_____/   \/_____/

------------===[ +1955-NOV-05T06:00:00.000Z ]===------------

                          "OUTATIME!"

  "This is what makes time travel possible."
  -Doc Brown

  "Forget about the Date type. Here comes the Datizo type."
  -Redger

Note:
	Datizo is the DAte/TIme/ZOne [re]processor.

	This software focuses on calendrical calculations,
	conversions between timestamps of various operating
	systems and languages.

	Most algorithms are from the book:
		Calendrical Calculations (3r edition)

Software license:
	GPL3

Author:
    'Redger' I. CORNICE <idriss.cornice@gmail.com>

Version:
	2015-01-29
++/

module datizo;

import std.stdio;
import std.exception;
import std.regex;
import std.string;
import std.conv;

alias ubyte  uint08;
alias ushort uint16;
alias uint   uint32;
alias ulong  uint64;

alias byte   int08;
alias short  int16;
alias int    int32;
alias long   int64;

enum Error {
	NAD = "not a Datizo",
	
	//YEAR_ZERO = "year zero is meaningless",
	YEAR_OOR = "year is out of range [-9999 .. +9999]",
	MONTH_OOR = "month is out of range [1 .. 12]",
	DAY_OOR = "day is out of range [1 .. %d]",
	
	HOUR_OOR = "hour is out of range [0 .. 23]",
	MINUTE_OOR = "minute is out of range [0 .. 59]",
	SECOND_OOR = "second is out of range [0 .. 59]",
	NANOSECOND_OOR = "nanosecond is out of range [0 .. 999999999]",
	
	TZ_OFFSET = "timezone offset is invalid",
	
	UNREADABLE_CLOCK = "clock is unreadable",
}

auto REG_ISO8601 = ctRegex!r"^([+\-]?[0-9]{4})-([0-9]{2}|[A-Za-z]{3})-([0-9]{2})(T([0-9]{2}):([0-9]{2}):([0-9]{2})(\.[0-9]{1,9})?(Z|([+\-])([0-9]{2}):([0-9]{2})))?$";

const string[12] MONTH_NAMES = [
	"January", "February", "March", "April",
		"May", "June", "July", "August",
			"September", "October", "November", "December"
];

const string[7] WEEKDAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

const int16[12][2] DAYS_BEFORE_MONTH = [
	[0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334],
	[0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335],
];

enum Epoch {
	GREGORIAN = 1,
}
struct GregorianCal {
	//source:
	//http://stackoverflow.com/questions/9852837/leap-year-check-using-bitwise-operators-amazing-speed
	static bool isLeapYear(int64 year) {
	 	return !(year & 3 || year & 15 && !(year % 25));
	}

	static int08 lastDayOfMonth(int64 year, int08 month) {
		int08 feb = isLeapYear(year) ? 29 : 28;
		return cast(int08)[31, feb, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
	}	
}


struct Date {
	int64 year;
	int08 month;
	int08 day;

	int08 lastDOM;
	bool isLeapYear;

	private this(int64 y, int08 mo, int08 d) {
		enforce( y  >= -9999 && y  <= 9999, Error.YEAR_OOR  );
		enforce( mo >=     1 && mo <=   12, Error.MONTH_OOR );
		
		isLeapYear = GregorianCal.isLeapYear(y);
		lastDOM    = GregorianCal.lastDayOfMonth(y, mo);
		enforce(  d >=     1 && d  <= lastDOM, format(Error.DAY_OOR, lastDOM) );
		
		year = y;
		month = mo;
		day = d;
	}

	public static of(int64 y, int08 mo, int08 d) {
		return Date(y, mo, d);
	}

	public static immutable Date EPOCH = Date.of(1, 1, 1);

	string toString() {
		return format("%04d-%02d-%02d", year, month, day);
	}
}

struct Time {
	int08 hour;
	int08 minute;
	int08 second;
	int32 nanosecond;

	private this(int08 h, int08 mi, int08 s, int32 ns) {
		enforce( h  >= 0 && h  < 24,             Error.HOUR_OOR       );
		enforce( mi >= 0 && mi < 60,             Error.MINUTE_OOR     );
		enforce( s  >= 0 && s  < 60,             Error.SECOND_OOR     );
		enforce( ns >= 0 && ns < 1_000_000_000L, Error.NANOSECOND_OOR );
		
		hour = h;
		minute = mi;
		second = s;
		nanosecond = ns;	
	}

	public static of(int08 h, int08 mi, int08 s, int32 ns) {
		return Time(h, mi, s, ns);
	}
	
	public static immutable Time MIDNIGHT = Time.of( 0, 0, 0, 0);
	public static immutable Time NOON     = Time.of(12, 0, 0, 0);

	string toString() {
		return format("%02d:%02d:%02d.%09d", hour, minute, second, nanosecond);
	}
}

enum Sign {
	MINUS = -1,
	PLUS = 1,
}

struct Zone {
	char symbol = '+';
	Sign sign = Sign.PLUS;
	Time offset = Time.MIDNIGHT;
	
	private this(Sign si, int08 h, int08 mi) {
		sign = si;
		symbol = "-+"[si >= 0];
		
		try {
			offset = Time(h, mi, 0, 0);
		}
		catch( Exception ex ) {
			throw new Exception( Error.TZ_OFFSET );
		}
	}

	public static of(Sign si, int08 h, int08 mi) {
		return Zone(si, h, mi);
	}
	
	public static immutable Zone ZULU = Zone.of(Sign.PLUS, 0, 0);

	string toString() {
		return "-+"[sign >= 0]~offset.toString[0..5];
	}
}

struct Clock {
	version (Windows) {
		//required imports for: GetSystemTime()
		private import std.c.windows.windows;

		//source: http://delphicikk.atw.hu/listaz.php?id=2667&oldal=52
		//link taken from date.d of the Phobos lib
		@property
		public static Datizo fromOS() {
			SYSTEMTIME now;
			GetSystemTime(&now);

			if (!now.wYear) {
				throw new Exception( Error.UNREADABLE_CLOCK );
			}

			return Datizo.of(
				cast(int64)now.wYear,
				cast(int08)now.wMonth,
				cast(int08)now.wDay,
				cast(int08)now.wHour,
				cast(int08)now.wMinute,
				cast(int08)now.wSecond,
				cast(int32)(now.wMilliseconds * 1_000_000)
			);
		}
	}
}

struct Parser {
	public static Datizo regex(string input) {
		auto m = match(input, REG_ISO8601);

		if (m.empty) {
			throw new Exception( Error.NAD );
		}

		//INIT
		Date da;
		Time ti = Time.MIDNIGHT;
		Zone zo = Zone.ZULU;

		//DATE PART
		int64 y = to!int64( m.captures[1] );

		int08 mo;
		switch( m.captures[2] ) {
			case "01", "JAN", "Jan", "jan": mo =  1; break;
			case "02", "FEB", "Feb", "feb": mo =  2; break;
			case "03", "MAR", "Mar", "mar": mo =  3; break;
			case "04", "APR", "Apr", "apr": mo =  4; break;
			case "05", "MAY", "May", "may": mo =  5; break;
			case "06", "JUN", "Jun", "jun": mo =  6; break;
			case "07", "JUL", "Jul", "jul": mo =  7; break;
			case "08", "AUG", "Aug", "aug": mo =  8; break;
			case "09", "SEP", "Sep", "sep": mo =  9; break;
			case "10", "OCT", "Oct", "oct": mo = 10; break;
			case "11", "NOV", "Nov", "nov": mo = 11; break;
			case "12", "DEC", "Dec", "dec": mo = 12; break;
			
			default:
				break;
		}

		int08 d = to!int08( m.captures[3] );

		da = Date.of(y, mo, d);

		//TIME PART
		if (m.captures[4] != null) {
			int08 h  = to!int08( m.captures[5] );
			int08 mi = to!int08( m.captures[6] );
			int08 s  = to!int08( m.captures[7] );
			
			int32 ns;
			if (m.captures[8] != null) {
				string nanosecond = m.captures[8][1..$] ~ "00000000";
				ns   = to!int32( nanosecond[0..9] );
			}
			
			ti = Time.of(h, mi, s, ns);
			
			//ZONE PART
			if (m.captures[9] != "Z") {
				Sign  zsi = (m.captures[10] == "+") ? Sign.PLUS : Sign.MINUS;				
				int08 zh  = to!int08( m.captures[11] );
				int08 zmi = to!int08( m.captures[12] );
				
				zo = Zone.of(zsi, zh, zmi);
			}
		}

		return Datizo.of(da, ti, zo);
	}
}

struct Datizo {
	Date date;
	Time time;
	Zone zone;

	private this(Date da, Time ti, Zone zo) {
		date = da;
		time = ti;
		zone = zo;

		//TODO other validations go here
		//compute ratadie with time + zone, leap seconds, etc
	}

	public static Datizo of(Date da, Time ti, Zone zo) {
		return Datizo(da, ti, zo);
	}

	public static Datizo of(int64 y, int08 mo, int08 d) {
		Date da = Date.of(y, mo, d);
		Time ti = Time.MIDNIGHT;
		Zone zo = Zone.ZULU;

		return Datizo(da, ti, zo);
	}

	public static Datizo of(int64 y, int08 mo, int08 d, int08 h, int08 mi, int08 s, int32 ns) {
		Date da = Date.of(y, mo, d);
		Time ti = Time.of(h, mi, s, ns);
		Zone zo = Zone.ZULU;

		return Datizo(da, ti, zo);
	}

	public static Datizo of(int64 y, int08 mo, int08 d, int08 h, int08 mi, int08 s, int32 ns, Sign zsi, int08 zh, int08 zmi) {
		Date da = Date.of(y, mo, d);
		Time ti = Time.of(h, mi, s, ns);
		Zone zo = Zone.of(zsi, zh, zmi);

		return Datizo(da, ti, zo);
	}

	public static Datizo now() {
		return Clock.fromOS();
	}
	
	public static Datizo of(string input) {
		return Parser.regex( input.idup );
	}
	
	public void print() {
		writeln();
		writeln("ISO 8601: ",         toString());
		writeln();
		writeln("year: ",             date.year);
		writeln("month: ",            date.month);
		//writeln("month name: ",       date.monthName);
		writeln("day: ",              date.day);
		//writeln("weekday: ",          date.weekday);
		//writeln("weekday name: ",     date.weekdayName);
		writeln();
		//writeln("ordinal day: ",      date.ordinalDay);
		//writeln("rata die: ",         date.rd);
		writeln();
		writeln("hour: ",             time.hour);
		writeln("minute: ",           time.minute);
		writeln("second: ",           time.second);
		writeln("nanosecond: ",       time.nanosecond);
		writeln();
		writeln("timezone sign: ",    zone.symbol);
		writeln("timezone hour: ",    zone.offset.hour);
		writeln("timezone minute: ",  zone.offset.minute);
		writeln();
		//writeln("weekdate: ",         date.weekdate);
	}

	string toString() {
		return date.toString~'T'~time.toString~zone.toString;
	}
}

//TODO unit tests

void main() {

	// simple check 1
	Datizo dtz = Datizo.of("1985-OCT-26T01:21:00Z");
	dtz.print();

	// simple check 3
	Datizo now = Datizo.now();
	now.print();

}