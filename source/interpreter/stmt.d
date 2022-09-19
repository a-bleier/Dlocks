module source.interpreter.stmt;
import source.interpreter.scanner;
import source.interpreter.parser;
import std.variant;
import source.interpreter.expr;

class Stmt
{
	abstract Variant accept(Visitor visitor);
}
interface Visitor 
{
	Variant visitBlockStmt(Block stmt);
	Variant visitExpressionStmt(Expression stmt);
	Variant visitFunctionStmt(Function stmt);
	Variant visitReturnStmt(Return stmt);
	Variant visitIfStmt(If stmt);
	Variant visitPrintStmt(Print stmt);
	Variant visitBreakStmt(Break stmt);
	Variant visitVarStmt(Var stmt);
	Variant visitWhileStmt(While stmt);
}
class Block : Stmt
{
	this(Stmt[] statements)
	{
		this.statements = statements;
	}

	Stmt[] statements;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitBlockStmt(this);
	}
}
class Expression : Stmt
{
	this(Expr expression)
	{
		this.expression = expression;
	}

	Expr expression;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitExpressionStmt(this);
	}
}
class Function : Stmt
{
	this(Token name, Token[] params, Stmt[] body)
	{
		this.name = name;
		this.params = params;
		this.body = body;
	}

	Token name;
	Token[] params;
	Stmt[] body;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitFunctionStmt(this);
	}
}
class Return : Stmt
{
	this(Token keyword, Expr value)
	{
		this.keyword = keyword;
		this.value = value;
	}

	Token keyword;
	Expr value;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitReturnStmt(this);
	}
}
class If : Stmt
{
	this(Expr condition, Stmt thenBranch, Stmt elseBranch)
	{
		this.condition = condition;
		this.thenBranch = thenBranch;
		this.elseBranch = elseBranch;
	}

	Expr condition;
	Stmt thenBranch;
	Stmt elseBranch;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitIfStmt(this);
	}
}
class Print : Stmt
{
	this(Expr expression)
	{
		this.expression = expression;
	}

	Expr expression;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitPrintStmt(this);
	}
}
class Break : Stmt
{
	this()
	{
	}


	override Variant accept(Visitor visitor)
	{
		return visitor.visitBreakStmt(this);
	}
}
class Var : Stmt
{
	this(Token name, Expr initializer)
	{
		this.name = name;
		this.initializer = initializer;
	}

	Token name;
	Expr initializer;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitVarStmt(this);
	}
}
class While : Stmt
{
	this(Expr condition, Stmt body)
	{
		this.condition = condition;
		this.body = body;
	}

	Expr condition;
	Stmt body;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitWhileStmt(this);
	}
}
