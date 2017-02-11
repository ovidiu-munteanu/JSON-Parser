# JSON-Parser #
JFlex Lexer + CUP Parser for the JSON Data Interchange Format, based on
the ECMA-404 standard ([json.org](http://www.json.org))


## Overview ##
This JSON parser consists of two components, a JFlex lexer 
(_jflex/Scanner.jflex_) and a CUP parser (_cup/Parser.cup_). The lexical 
and grammar rules implemented follow the ECMA-404 standard. There are 
three minor exceptions from the standard specification: 
*	a single value is NOT considered to be valid JSON, only an array or 
an object;
*	a leading plus sign is allowed in front of numerical values, not only
a minus sign (i.e. 12, +12 and -12 are all allowed as valid numerical 
values); this decision is based on the fact that in a number of science 
fields (e.g. physics) it is common practice to use a + sign in front of 
certain numerical values in order to denote specific properties that 
cannot be easily expressed otherwise (e.g. electrical charge, the 
direction of a force vector, etc.)
* empty strings are allowed both as keys and values within objects and as 
values within arrays (e.g. "":"", "": "value", "key": "" are all allowed 
as valid pairs).

The parser will accept input in the form of a text file and will output to 
console information regarding the components of the JSON object as it is 
parsed, and whether the parsing was successful (i.e. the input is a valid 
JSON object) or not. 


##Prerequisites
To compile and build the JSON parser you need to install the latest [Java SDK](http://www.oracle.com/technetwork/java/javase/overview/index.html) and 
[Apache Ant](http://ant.apache.org/).


##Quick Start
Clone this repository into a local folder and build using ant, then execute 
the parser using the following commands:
```
ant jar

java -jar jar/parser.jar <path_to_your_JSON_file>
```


##Test Inputs
A number of test input files are included in the _/tests_ folder. Run these 
use the command systax given in the __Quick Start__ section, for example:
```
java -jar jar/parser.jar tests/valid_doom.test
```
Descriptions for all the tests and the expected results can be found in the 
_List of tests.pdf_


##Parser Output
The parser will output to console information regarding the components of the JSON object as it is parsed, and whether the parsing was successful (i.e. the input is a valid JSON object) or not. 


##Parser Implementation
The parser consists of two components, a JFlex lexer (_jflex/Scanner.jflex_) 
and a CUP parser (_cup/Parser.cup_).


###Scanner.jflex (inside the _/jflex_ folder)
The lexer file defines the main tokens of the JSON format. To begin with, 
a number of simple regex macros are defined, which are then used to define 
more complex macros. These macros are then used to define the tokens. 

####Start off by defining a number of helper macros####
The set of hex digits will be used for the string definition which may 
include /u followed by 4 hex digits, e.g "/uA1C0"
```
hex_digit = [0-9a-fA-F]
```

For string values, the set of valid characters as given by the ECMA-404
JSON standard consists of any UNICODE character except for " or \ or the
control characters U+0000 through U+FFFF, unless they are part of an escape
sequence. For clarity, two intermediate macros are defined: one for the
valid UNICODE character set, and another for the valid escape sequences.
According to the ECMA-404 JSON standard, the valid escape sequences are
\" (single set of quotation marks), \\ (single backslash), \b, \f, \n, \r,
\t, and \u followed by 4 hex digits. 
```
valid_set_char = [^\u0000-\u001F\"\\]

valid_escape_seq = \\\" | \\\\ | \\/ | \\b | \\f | \\n | \\r | \\r | \\t | (\\u({hex_digit}{4}))

valid_character = {valid_set_char} | {valid_escape_seq}
```

Therefore, a string is a set of zero (i.e. the empty string) or more valid
characters between double quotation marks
```
string = \"{valid_character}*\"
```

Macros for the numeric sign (i.e. an optional + or -), the decimal dot, 
and case insensitive exponential notation. Strictly speaking, according to
the ECMA-404 JSON standard, numerical values cannot be preceded by an 
optional + sign, only exponents. In my implementation however I decided to
allow an optional + sign in front of a numerical value. In a number of 
science fields (e.g. physics) it is common practice to use a + sign in 
front of a value in order to denote specific properties that cannot be 
expressed otherwise (e.g electrical charge, direction of a force vector,
etc.)
```
sign = ["+"-]?
dot = "."
exp = [eE]
digit = [0-9]
```

The integer part of a number is either a single zero or any other
combination of digits with a leading non-zero digit. According to the JSON
specification, this macro rejects integer parts that have multiple leading
zeros such as "000" or "007"
```
int_part = 0|[1-9]{digit}* 
```

The decimal part of a number is any combination of one or more digits
with any number of trailing zeroes. E.g. "42.0", "42.00" or "42.4200" 
all have an acceptable decimal part 
```
dec_part = {digit}+
```


####Define more comples macros using these helper macros####

Integer numbers consist of an integer part preceded by a numeric sign 
As defined earlier, the numeric sign is optional
```
int_num = {sign} {int_part}
```

Real numbers are composed of an integer number followed by a decimal dot
and a decimal part
```
real_num = {int_num} {dot} {dec_part}
```
 
Scientific (exponential) notation numbers consist of an integer or real
number followed by an exponential part. This in turn is composed of the
exponential notation followed by a signed or unsigned sequence of digits.
```
exp_num = ({int_num} | {real_num}) {exp} {sign} {digit}+
```

Boolean values, i.e. the literal tokens true and false
```
boolean = "true" | "false"
```

Null value, i.e. the literal token null
```
null = "null"
```

####Define the JSON tokens using all these macros ####
Scan for the allowable JSON "punctuation" tokens and return the relevant
symbols to the CUP parser
```
"{" { return sf.newSymbol("Left Curly Bracket",  sym.LCRLBRKT); }
"}" { return sf.newSymbol("Right Curly Bracket", sym.RCRLBRKT); }

"[" { return sf.newSymbol("Left Square Bracket",  sym.LSQRBRKT); }
"]" { return sf.newSymbol("Right Square Bracket", sym.RSQRBRKT); }

"," { return sf.newSymbol("Comma", sym.COMMA); }
":" { return sf.newSymbol("Colon", sym.COLON); }
```

Scan for valid JSON tokens using the macros defined earlier, and return 
the relevant symbols and values (except for null) to the CUP parser 
```
{string}   { return sf.newSymbol("String", sym.STRING, new String(yytext())); }

{int_num}  { return sf.newSymbol("Integer", sym.INT_NUM, new Long(yytext())); }

{real_num} { return sf.newSymbol("Real", sym.REAL_NUM, new Double(yytext())); }

{exp_num}  { return sf.newSymbol("Exponential", sym.EXP_NUM, new Double(yytext())); }

{boolean}  { return sf.newSymbol("Boolean", sym.BOOLEAN, new Boolean(yytext())); }

{null}	   { return sf.newSymbol("Null", sym.NULL); }
```
Scan for and ignore all white spaces, i.e. simple space, tab, carriage return,
new line, and form feed 
```
[ \t\r\n\f] { /* ignore white spaces */ }
```

###Parser.cup (inside the _/cup_ folder)
####Declare terminals####
Start off by declaring terminals that have no associated value i.e. JSON 
"punctuation" tokens { } [ ] , : and the null literal.
```
terminal LCRLBRKT, RCRLBRKT, LSQRBRKT, RSQRBRKT, COMMA, COLON, NULL;
```
Declare terminals that have associated values. The non terminal declarations
included further on are also used to print out these associated values.
```
terminal String STRING;
terminal Long INT_NUM;
terminal Double REAL_NUM, EXP_NUM;
terminal Boolean BOOLEAN;
```
####Declare non-terminals####
Declare the non-terminals that can be reduced to other non-terminals in the 
same list or terminals defined earlier. 
```
non terminal success, valid_json, value, object, member_list, pair, array, value_list;
```

Declare a helper non terminal placed at the top of tree to print out a 
success message after whole tree is parsed.
```
success ::= valid_json  {: System.out.println("\nParsing completed successfully."); :};
```

Helper non-terminal used to define valid JSON if it either and array or an object.
Note: this definition does NOT allow a single value as valid JSON. 
```
valid_json ::= array | object;
```


JSON object non-terminal derives a JSON object that can either be empty { } 
or contain a list of members { member_list }. Also used to print out 
information messages about what is being parsed.
```
object ::= LCRLBRKT {: System.out.println("\nParsing object... "); :} 
		   RCRLBRKT {: System.out.println("Empty object parsed."); :} 
		   | 
           LCRLBRKT {: System.out.println("\nParsing object... "); :} 
		   member_list 
		   RCRLBRKT {: System.out.println("Object parsed."); :}; 
```

Member list non terminal used to derive a list of one or more JSON pairs;
used in the defintion of the object non-terminal above. 
```
member_list ::= member_list COMMA pair | pair;
```

JSON pair non terminal derives a JSON pair in the format key : value; as 
per the JSON specification, a key can only be a string. Also used to print
the associated value of the parsed key.
```
pair ::= STRING:k {: System.out.print("Key " + k + " : "); :} COLON value;
```

JSON array non terminal derives a JSON array that can either be empty [ ]
or contain a list of values [value_list]. Also used to print out information
messages about what is being parsed. 
```
array ::= LSQRBRKT {: System.out.println("\nParsing array... "); :} 
		  RSQRBRKT {: System.out.println("Empty array parsed."); :}
		  | 
		  LSQRBRKT {: System.out.println("\nParsing array... "); :} 
		  value_list 
		  RSQRBRKT {: System.out.println("Array parsed."); :};
```

Value list non terminal similar to the member list declared earlier, derives
a list of one or more JSON values. Used in the definition of the array non
terminal above.
```
value_list ::= value_list COMMA value | value;
```

Non terminal used to derive JSON values. According to the JSON specification
a value can be either a string, a number (in this case split into integer, 
real and real in exponential notation), a boolean or null numeral, or a 
whole array or object (these in turn could be composed as decribed above, so
in effect this also a recursive derivation with any number of nested levels). 
NOTE: According to the JSON specification a maximum of 15 nested levels is 
allowed. However, the number of nested levels is not checked in this 
implementation.   
```
value ::= STRING  :s {: System.out.print(s + " (string)\n"); :} 
		  |
		  INT_NUM :n {: System.out.print(n + " (integer number)\n"); :} 
		  | 
		  REAL_NUM:d {: System.out.print(d + " (real number)\n"); :} 
		  |
		  EXP_NUM :e {: System.out.print(e.toString() 
			+ " (number in scientific notation)\n"); :} 
		  |
		  BOOLEAN :b {: System.out.print(b + " (boolean literal)\n"); :} 
		  |
		  NULL {: System.out.print("null (null literal)\n"); :} 
		  |
		  array 
		  | 
		  object;
```
