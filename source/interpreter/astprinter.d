module source.interpreter.astprinter;

import source.interpreter.expr;
import source.interpreter.scanner;
import source.interpreter.parser;
import std.stdio;
import std.conv;
import std.variant;

class AstPrinter : Visitor
{
	Variant visitBinaryExpr(Binary expr)
	{
		return parenthesize(expr.operator.lexeme,
                        expr.left, expr.right);
	}

		public Variant visitAssignExpr(Assign expr)
	{
		return Variant();
	}

	Variant visitVariableExpr(Variable expr)
	{
		return Variant();	
	
	}

	Variant visitGroupingExpr(Grouping expr)
	{

		return parenthesize("group", expr.expression);
	}

	Variant visitLiteralExpr(Literal expr)
	{

		if (!expr.value.hasValue) return Variant(Variant("nil"));
    	return expr.value;
	}

	Variant visitUnaryExpr(Unary expr)
	{

		return parenthesize(expr.operator.lexeme, expr.right);
	}

	string print(Expr expr)
	{

		Variant var = expr.accept(this);
		return var.coerce!string();
	}

	private Variant parenthesize(string name, Expr[] exprs...)
	{
		string builder = "";

		builder ~= "(";
		builder ~= name;
		foreach (Expr expr ; exprs)
		{
			builder ~= " ";
			builder ~= to!string(expr.accept(this));
		}

		builder ~= ")";

		return Variant(builder);
	}
}

void printTest()
{
	Binary expression = new Binary(
		new Unary(
			new Token(TokenType.MINUS, "-", Variant(null), 1),
			new Literal(Variant("nil"))),
		new Token(TokenType.STAR, "*", Variant(null), 1),
		new Grouping(
				new Literal(Variant(45.67))));
	auto printer = new AstPrinter();
	writeln(printer.print(expression));
}