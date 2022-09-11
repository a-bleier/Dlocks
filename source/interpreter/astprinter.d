module source.interpreter.astprinter;

import source.interpreter.expr;
import source.interpreter.scanner;
import std.stdio;
import std.conv;

class AstPrinter : Visitor
{
	VisitorResult visitBinaryExpr(Binary expr)
	{
		writeln("here2");
		return parenthesize(expr.operator.lexeme,
                        expr.left, expr.right);
	}

	VisitorResult visitGroupingExpr(Grouping expr)
	{

		writeln("here3");
		return parenthesize("group", expr.expression);
	}

	VisitorResult visitLiteralExpr(Literal expr)
	{

		writeln("here4");
		if (expr.value.sVal is null) return VisitorResult(Value("nil"));
    	return VisitorResult(expr.value);
	}

	VisitorResult visitUnaryExpr(Unary expr)
	{

		writeln("here5");
		return parenthesize(expr.operator.lexeme, expr.right);
	}

	string print(Expr expr)
	{

		writeln("printing");
		return expr.accept(this).value.sVal;
	}

	private VisitorResult parenthesize(string name, Expr[] exprs...)
	{
		writeln("here6");
		string builder = "";

		builder ~= "(" ~ name;
		foreach (Expr expr ; exprs)
		{
			builder ~= " ";
			builder ~= to!string(expr.accept(this).value);
		}

		builder ~= ")";
		writeln(builder);

		return VisitorResult(Value(builder));
	}
}

void printTest()
{
	Binary expression = new Binary(
		new Unary(
			new Token(TokenType.MINUS, "-", Value(null), 1),
			new Literal(Value(123))),
		new Token(TokenType.STAR, "*", Value(null), 1),
		new Grouping(
				new Literal(Value(45.67))));
	auto printer = new AstPrinter();
	writeln(printer.print(expression));
}