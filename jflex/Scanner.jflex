import java_cup.runtime.SymbolFactory;

%%

%unicode
%cup
%class Scanner
%{
	public Scanner(java.io.InputStream r, SymbolFactory sf){
		this(r);
		this.sf=sf;
	}
	private SymbolFactory sf;
%}
%eofval{
    return sf.newSymbol("EOF",sym.EOF);
%eofval}


// Start off by defining a number of helper macros:

// The set of hex digits: this will be used for the string definition which
// may include /u followed by 4 hex digits, e.g "/uA1C0"

hex_digit = [0-9a-fA-F]


// For string values, the set of valid characters as given by the ECMA-404
// JSON standard consists of any UNICODE character except for " or \ or the
// control characters U+0000 through U+FFFF, unless they are part of an escape
// sequence. For clarity, two intermediate macros are defined: one for the
// valid UNICODE character set, and another for the valid escape sequences.
// According to the ECMA-404 JSON standard, the valid escape sequences are
// \" (single set of quotation marks), \\ (single backslash), \b, \f, \n, \r,
// \t, and \u followed by 4 hex digits. 

valid_set_char = [^\u0000-\u001F\"\\]

// valid_escape_seq = \\\" | \\\\ | \\/ | \\b | \\f | \\n | \\r | \\r | \\t | (\\u({hex_digit}{4}))
// or in a more condensed form:
valid_escape_seq = \\([\"\\/bfnrt]|(u({hex_digit}{4})))

valid_character = {valid_set_char} | {valid_escape_seq}


// Therefore, a string is a set of zero (i.e. the empty string) or more valid
// characters between double quotation marks

string = \"{valid_character}*\"


// Macros for the numeric sign (i.e. an optional + or -), the decimal dot, 
// and case insensitive exponential notation. Strictly speaking, according to
// the ECMA-404 JSON standard, numerical values cannot be preceded by an 
// optional + sign, only exponents. In my implementation however I decided to
// allow an optional + sign in front of a numerical value. In a number of 
// science fields (e.g. physics) it is common practice to use a + sign in 
// front of a value in order to denote specific properties that cannot be 
// expressed otherwise (e.g electrical charge, direction of a force vector,
// etc.)

sign = ["+"-]?
dot = "."
exp = [eE]
digit = [0-9]


// The integer part of a number is either a single zero or any other
// combination of digits with a leading non-zero digit. According to the JSON
// specification, this macro rejects integer parts that have multiple leading
// zeros such as "000" or "007"

int_part = 0|[1-9]{digit}* 


// The decimal part of a number is any combination of one or more digits
// with any number of trailing zeroes. E.g. "42.0", "42.00" or "42.4200" 
// all have an acceptable decimal part 

dec_part = {digit}+


// Integer numbers consist of an integer part preceded by a numeric sign 
// As defined earlier, the numeric sign is optional
int_num = {sign} {int_part}


// Real numbers are composed of an integer number followed by a decimal dot
// and a decimal part

real_num = {int_num} {dot} {dec_part}

 
// Scientific (exponential) notation numbers consist of an integer or real
// number followed by an exponential part. This in turn is composed of the
// exponential notation followed by a signed or unsigned sequence of digits.

exp_num = ({int_num} | {real_num}) {exp} {sign} {digit}+


// Boolean values, i.e. the literal tokens true and false

boolean = "true" | "false"


// Null value, i.e. the literal token null

null = "null"


%%

// Scan for the allowable JSON "punctuation" tokens and return the relevant
// symbols to the CUP parser

"{" { return sf.newSymbol("Left Curly Bracket",  sym.LCRLBRKT); }
"}" { return sf.newSymbol("Right Curly Bracket", sym.RCRLBRKT); }

"[" { return sf.newSymbol("Left Square Bracket",  sym.LSQRBRKT); }
"]" { return sf.newSymbol("Right Square Bracket", sym.RSQRBRKT); }

"," { return sf.newSymbol("Comma", sym.COMMA); }
":" { return sf.newSymbol("Colon", sym.COLON); }


// Scan for valid JSON tokens using the macros defined earlier, and return 
// the relevant symbols and values (except for null) to the CUP parser 

{string}   { return sf.newSymbol("String", sym.STRING, new String(yytext())); }

{int_num}  { return sf.newSymbol("Integer", sym.INT_NUM, new Long(yytext())); }

{real_num} { return sf.newSymbol("Real", sym.REAL_NUM, new Double(yytext())); }

{exp_num}  { return sf.newSymbol("Exponential", sym.EXP_NUM, new Double(yytext())); }

{boolean}  { return sf.newSymbol("Boolean", sym.BOOLEAN, new Boolean(yytext())); }

{null}	   { return sf.newSymbol("Null", sym.NULL); }


// Scan for and ignore all white spaces, i.e. simple space, tab, carriage return,
// new line, and form feed 

[ \t\r\n\f] { /* ignore white spaces */ }


// Scan for any other characters not matching one of the above tokens. Any such 
// character is unexpected so if one is encountered, there must be a formating 
// error in the input. Thus, print a message to the error stream including the 
// offending character, then stop and exit. 

. { 
    System.err.println("\nEncountered unexpected character: "+yytext() + "\nParsing stopped.");  
	System.out.println("\nParsing did NOT complete successfully. Please check your input file.");	
	System.exit(1);
  }
