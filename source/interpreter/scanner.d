module source.interpreter.scanner;

import source.lox;
import std.stdio;
import std.format;
import std.conv;
import std.variant;

enum TokenType
{
	// Single-character tokens.
	LEFT_PAREN,
	RIGHT_PAREN,
	LEFT_BRACE,
	RIGHT_BRACE,
	COMMA,
	DOT,
	MINUS,
	PLUS,
	SEMICOLON,
	SLASH,
	STAR,
	QUESTION_MARK,
	COLON,

	// One or two character tokens.
	BANG,
	BANG_EQUAL,
	EQUAL,
	EQUAL_EQUAL,
	GREATER,
	GREATER_EQUAL,
	LESS,
	LESS_EQUAL,

	// Literals.
	IDENTIFIER,
	STRING,
	NUMBER,

	// Keywords.
	AND,
	CLASS,
	ELSE,
	FALSE,
	FUN,
	FOR,
	IF,
	NIL,
	OR,
	PRINT,
	RETURN,
	SUPER,
	THIS,
	TRUE,
	VAR,
	WHILE,

	EOF
}

class Token
{
	TokenType type;
	string lexeme;
	Variant literal;
	int line;

	this(TokenType type, string lexeme, Variant literal, int line)
	{
		this.type = type;
		this.lexeme = lexeme;
		this.literal = literal;
		this.line = line;

	}

	public override string toString()
	{
		return format("%d %s %d", type, lexeme, line);
	}
}

class Scanner
{
	private immutable string source;
	private Token[] tokens;
	private const TokenType[string] keywords;

	private int start = 0, current = 0, line = 1;

	this(string source)
	{
		this.source = source;
		this.tokens = null;
		keywords = [
			"and": TokenType.AND,
			"class": TokenType.CLASS,
			"else": TokenType.ELSE,
			"false": TokenType.FALSE,
			"for": TokenType.FOR,
			"fun": TokenType.FUN,
			"if": TokenType.IF,
			"nil": TokenType.NIL,
			"or": TokenType.OR,
			"print": TokenType.PRINT,
			"return": TokenType.RETURN,
			"super": TokenType.SUPER,
			"this": TokenType.THIS,
			"true": TokenType.TRUE,
			"var": TokenType.VAR,
			"while": TokenType.WHILE
		];
	}

	Token[] scanTokens()
	{
		while (!this.isAtEnd())
		{
			start = current;
			scanToken();
		}

		tokens ~= new Token(TokenType.EOF, "", Variant(), line);
		return this.tokens;
	}

	private bool isAtEnd()
	{
		return this.current >= source.length;
	}

	private void addToken(TokenType type) //Produces a token of type type
	{
		this.addToken(type, Variant());
	}

	private void addToken(TokenType type, Variant literal) //Produces a token of type type and value literal
	{
		tokens ~= new Token(type, this.source[start .. current], literal, line);
	}

	private char advance() //Consumes a character
	{
		return source[current++];
	}

	private void scanToken()
	{
		char c = advance();
		switch (c)
		{
		case '(':
			addToken(TokenType.LEFT_PAREN);
			break;
		case ')':
			addToken(TokenType.RIGHT_PAREN);
			break;
		case '{':
			addToken(TokenType.LEFT_BRACE);
			break;
		case '}':
			addToken(TokenType.RIGHT_BRACE);
			break;
		case ',':
			addToken(TokenType.COMMA);
			break;
		case '.':
			addToken(TokenType.DOT);
			break;
		case '-':
			addToken(TokenType.MINUS);
			break;
		case '+':
			addToken(TokenType.PLUS);
			break;
		case ';':
			addToken(TokenType.SEMICOLON);
			break;
		case '*':
			addToken(TokenType.STAR);
			break;
		case '!':
			addToken(match('=') ? TokenType.BANG_EQUAL : TokenType.BANG);
			break;
		case '=':
			addToken(match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);
			break;
		case '<':
			addToken(match('=') ? TokenType.LESS_EQUAL : TokenType.LESS);
			break;
		case '>':
			addToken(match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER);
			break;
		case '?':
			addToken(TokenType.QUESTION_MARK);
			break;
		case ':':
			addToken(TokenType.COLON);
			break;
		case '/':
			if (match('/')) //single line coments
			{
				while (peek() != '\n' && !isAtEnd())
					advance();
			}
			else if (match('*')) //multiline comments
			{
				while (peek() != '*' && peekNext() != '/' && !isAtEnd())
					advance();

				if (isAtEnd())
					reportError(line, "Unterminated multi line comment");

				advance();
				advance();
			}
			else //Otherwise, it's indeed a slash
			{
				addToken(TokenType.SLASH);
			}
			break;
			//meaningless characters
		case ' ':
			goto case;
		case '\r':
			goto case;
		case '\t':
			break;
		case '\n':
			this.line++;
			break;
		case '"':
			scanString();
			break;
		default:
			if (isDigit(c))
			{
				number();
			}
			else if (isAlpha(c))
			{
				identifier();
			}
			else
			{
				reportError(this.line, "Unexpected character");
			}
		}
	}

	private bool isDigit(char c)
	{
		return c >= '0' && c <= '9';
	}

	private bool isAlpha(char c)
	{
		return (c >= 'a' && c <= 'z') ||
			(c >= 'A' && c <= 'Z') ||
			c == '_';
	}

	private bool isAlphaNumeric(char c)
	{
		return isAlpha(c) || isDigit(c);
	}

	private void identifier()
	{
		while (isAlphaNumeric(peek()))
			advance();

		auto text = source[start .. current];
		addToken((text in keywords) != null ? keywords[text] : TokenType.IDENTIFIER);
	}

	private void number()
	{
		while (isDigit(peek()))
			advance();

		if (peek() == '.' && isDigit(peekNext()))
		{
			advance();

			while (isDigit(peek()))
				advance();
		}

		addToken(TokenType.NUMBER, Variant(to!double(source[start .. current])));
	}

	//only consumes when the character is expected
	private bool match(char expected)
	{
		if (isAtEnd())
			return false;
		if (source[current] != expected)
			return false;

		current++;
		return true;
	}

	private char peek()
	{
		if (isAtEnd())
			return '\0';
		return source[current];
	}

	private char peekNext()
	{
		if (current + 1 >= source.length)
			return '\0';
		return source[current + 1];
	}

	private void scanString()
	{
		while (peek() != '"' && !isAtEnd())
		{
			if (peek() == '\n')
				line++;
			advance();
		}
		if (isAtEnd())
		{
			reportError(line, "Unterminated string");
		}

		//The closing ".
		advance();

		//Trim the surrounding quotes
		string value = source[start + 1 .. current-1];
		addToken(TokenType.STRING, Variant(value));
	}

}
