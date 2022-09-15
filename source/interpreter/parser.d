module source.interpreter.parser;

import std.variant;
import std.stdio;
import source.interpreter.scanner;
import source.interpreter.expr;
import source.interpreter.stmt;
import source.lox;

class Parser
{
	private Token[] tokens;
	private int current = 0;

	this(Token[] tokens)
	{
		this.tokens = tokens;
	}

	Stmt[] parse()
	{
		Stmt[] statements;
		while (!isAtEnd())
		{
			statements ~= declaration();
		}
		return statements;
	}

	private Expr assignment()
	{
		Expr expr = ternary();

		if (match(TokenType.EQUAL))
		{
			Token equals = previous();
			Expr value = assignment();

			Variable var = cast(Variable) expr;
			if (var !is null)
			{
				Token name = var.name;
				return new Assign(name, value);
			}

			error(equals, "Invalid assignment target.");
		}

		return expr;
	}

	private Expr or()
	{
		Expr expr = and();
		while (match(TokenType.OR))
		{
			Token operator = previous();
			Expr right = and();
			expr = new Logical(expr, operator, right);
		}
		return expr;
	}

	private Expr and()
	{
		Expr expr = equality();
		while (match(TokenType.AND))
		{
			Token operator = previous();
			Expr right = equality();
			expr = new Logical(expr, operator, right);
		}
		return expr;
	}

	private Stmt declaration()
	{
		try
		{
			if (match(TokenType.VAR))
				return varDeclaration();

			return statement();
		}
		catch (ParseError error)
		{
			synchronize();
			return null;
		}
	}

	private Stmt varDeclaration()
	{
		Token name = consume(TokenType.IDENTIFIER, "Expect variable name.");

		Expr initializer = null;
		if (match(TokenType.EQUAL))
		{
			initializer = expression();
		}

		consume(TokenType.SEMICOLON, "Expect ';' after variable declaration.");
		return new Var(name, initializer);
	}

	private Stmt statement()
	{
		if (match(TokenType.PRINT))
			return printStatement();
		if (match(TokenType.IF))
			return ifStatement();
		if (match(TokenType.WHILE))
			return whileStatement();
		if (match(TokenType.FOR))
			return forStatement();
		if (match(TokenType.LEFT_BRACE))
			return new Block(block());
		return expressionStatement();
	}

	private Stmt printStatement()
	{
		Expr value = expression();
		consume(TokenType.SEMICOLON, "Expect ';' after value");
		return new Print(value);
	}

	private Stmt[] block()
	{
		Stmt[] statements;

		while (!check(TokenType.RIGHT_BRACE) && !isAtEnd())
		{
			statements ~= declaration();
		}

		consume(TokenType.RIGHT_BRACE, "Expect '}' after block.");
		return statements;
	}

	private Stmt ifStatement()
	{
		Expr condition = expression();
		consume(TokenType.RIGHT_PAREN, "Expect ')' after if condition");

		Stmt thenBranch = statement();
		Stmt elseBranch = null;
		//dangling else problem: Where to put the else after an series of ifs ? -> Always after the last if
		if (match(TokenType.ELSE))
		{
			elseBranch = statement();
		}

		return new If(condition, thenBranch, elseBranch);
	}

	private Stmt whileStatement()
	{
		consume(TokenType.LEFT_PAREN, "Expect '(' after 'while'.");
		Expr condition = expression();
		consume(TokenType.RIGHT_PAREN, "Expect ')' after condition.");
		Stmt body = statement();

		return new While(condition, body);
	}

	//We will desugar a for loop into a while loop
	private Stmt forStatement()
	{
		consume(TokenType.LEFT_PAREN, "Expect '(' after 'while'.");

		Stmt initializer;
		if (match(TokenType.SEMICOLON))
		{
			initializer = null;
		}
		else if (match(TokenType.VAR))
		{
			initializer = varDeclaration(); //';' will get matched
		}
		else
		{
			initializer = expressionStatement(); //';' will get matched
		}

		Expr condition = null;
		if (!check(TokenType.SEMICOLON))
		{
			condition = expression();
		}
		consume(TokenType.SEMICOLON, "Expect ';' after loop condition.");

		Expr increment = null;
		if (!check(TokenType.RIGHT_PAREN))
		{
			increment = expression();
		}
		consume(TokenType.RIGHT_PAREN, "Expect ')' after for clauses.");

		Stmt forBody = statement();

		if (increment !is null)
		{
			forBody = new Block([forBody, new Expression(increment)]);
		}

		if (condition is null)
			condition = new Literal(Variant(true));
		forBody = new While(condition, forBody);

		if (initializer !is null)
		{
			forBody = new Block([initializer, forBody]);
		}

		return forBody;
	}

	private Stmt expressionStatement()
	{
		Expr expr = expression();
		consume(TokenType.SEMICOLON, "Expect ';' after expression.");
		return new Expression(expr);
	}

	private Expr expression()
	{
		Expr expr = assignment();

		while (match(TokenType.COMMA))
		{
			Token op = previous();
			Expr right = expression();
			expr = new Binary(expr, op, right);
		}
		return expr;
	}

	private Expr ternary()
	{
		Expr expr = or();
		while (match(TokenType.QUESTION_MARK))
		{
			writeln("me here lol");
			Expr left = ternary();
			consume(TokenType.COLON, "Expect ':' in ternary operator");
			Expr right = ternary();
			expr = new Ternary(expr, left, right);
		}

		return expr;
	}

	private Expr equality()
	{
		Expr expr = comparison();

		while (match(TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL))
		{
			Token op = previous();
			Expr right = comparison();
			expr = new Binary(expr, op, right);
		}
		return expr;
	}

	private Expr comparison()
	{
		Expr expr = term();

		while (match(TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.LESS, TokenType
				.LESS_EQUAL))
		{
			Token operator = previous();
			Expr right = term();
			expr = new Binary(expr, operator, right);
		}

		return expr;
	}

	private Expr term()
	{
		Expr expr = factor();

		while (match(TokenType.MINUS, TokenType.PLUS))
		{
			Token operator = previous();
			Expr right = factor();
			expr = new Binary(expr, operator, right);
		}

		return expr;
	}

	private Expr factor()
	{
		Expr expr = unary();

		while (match(TokenType.SLASH, TokenType.STAR))
		{
			Token operator = previous();
			Expr right = unary();
			expr = new Binary(expr, operator, right);
		}

		return expr;
	}

	private Expr unary()
	{
		if (match(TokenType.BANG, TokenType.MINUS))
		{
			Token operator = previous();
			Expr right = unary();
			return new Unary(operator, right);
		}

		return primary();
	}

	private Expr primary()
	{
		if (match(TokenType.FALSE))
			return new Literal(Variant(false));
		if (match(TokenType.TRUE))
			return new Literal(Variant(true));
		if (match(TokenType.NIL))
			return new Literal(Variant());

		if (match(TokenType.NUMBER, TokenType.STRING))
		{
			return new Literal(previous().literal);
		}

		if (match(TokenType.LEFT_PAREN))
		{
			Expr expr = expression();
			consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
			return new Grouping(expr);
		}

		if (match(TokenType.IDENTIFIER,))
		{
			return new Variable(previous());
		}
		throw error(peek(), "Expect expression.");
	}

	private Token consume(TokenType type, string message) //only advance to the next token if it matches the type; otherwise print error message
	{
		if (check(type))
			return advance();

		throw error(peek(), message);
	}

	private bool match(TokenType[] types...) //advance to next token if it matches with a type in types
	{
		foreach (type; types)
		{
			if (check(type))
			{
				advance();
				return true;
			}
		}
		return false;
	}

	private bool check(TokenType type) //one token of look ahead
	{
		if (isAtEnd())
			return false;
		return peek().type == type;
	}

	private Token advance()
	{
		if (!isAtEnd())
			current++;
		return previous();
	}

	private bool isAtEnd()
	{
		return peek().type == TokenType.EOF;
	}

	private Token peek()
	{
		return tokens[current];
	}

	private Token previous()
	{
		return tokens[current - 1];
	}

	private ParseError error(Token token, string message)
	{
		reportError(token, message);
		return new ParseError();
	}

	private void synchronize()
	{
		advance();

		while (!isAtEnd())
		{
			if (previous().type == TokenType.SEMICOLON)
				return;

			switch (peek().type)
			{
			case TokenType.CLASS:
			case TokenType.FUN:
			case TokenType.VAR:
			case TokenType.FOR:
			case TokenType.IF:
			case TokenType.WHILE:
			case TokenType.PRINT:
			case TokenType.RETURN:
				return;
			default:
				break;
			}

			advance();
		}
	}
}

class ParseError : Exception
{
	this()
	{
		super("", __FILE__, __LINE__);
	}
}
