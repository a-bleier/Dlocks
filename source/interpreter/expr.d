module source.interpreter.expr;
import source.interpreter.scanner;
import source.interpreter.parser;
import std.variant;

class Expr
{
	abstract Variant accept(Visitor visitor);
}
interface Visitor 
{
	Variant visitAssignExpr(Assign expr);
	Variant visitTernaryExpr(Ternary expr);
	Variant visitBinaryExpr(Binary expr);
	Variant visitCallExpr(Call expr);
	Variant visitGetExpr(Get expr);
	Variant visitSetExpr(Set expr);
	Variant visitSuperExpr(Super expr);
	Variant visitThisExprExpr(ThisExpr expr);
	Variant visitGroupingExpr(Grouping expr);
	Variant visitLiteralExpr(Literal expr);
	Variant visitLogicalExpr(Logical expr);
	Variant visitUnaryExpr(Unary expr);
	Variant visitVariableExpr(Variable expr);
}
class Assign : Expr
{
	this(Token name, Expr value)
	{
		this.name = name;
		this.value = value;
	}

	Token name;
	Expr value;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitAssignExpr(this);
	}
}
class Ternary : Expr
{
	this(Expr condition, Expr left, Expr right)
	{
		this.condition = condition;
		this.left = left;
		this.right = right;
	}

	Expr condition;
	Expr left;
	Expr right;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitTernaryExpr(this);
	}
}
class Binary : Expr
{
	this(Expr left, Token operator, Expr right)
	{
		this.left = left;
		this.operator = operator;
		this.right = right;
	}

	Expr left;
	Token operator;
	Expr right;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitBinaryExpr(this);
	}
}
class Call : Expr
{
	this(Expr callee, Token paren, Expr[] arguments)
	{
		this.callee = callee;
		this.paren = paren;
		this.arguments = arguments;
	}

	Expr callee;
	Token paren;
	Expr[] arguments;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitCallExpr(this);
	}
}
class Get : Expr
{
	this(Expr object, Token name)
	{
		this.object = object;
		this.name = name;
	}

	Expr object;
	Token name;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitGetExpr(this);
	}
}
class Set : Expr
{
	this(Expr object, Token name, Expr value)
	{
		this.object = object;
		this.name = name;
		this.value = value;
	}

	Expr object;
	Token name;
	Expr value;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitSetExpr(this);
	}
}
class Super : Expr
{
	this(Token keyword, Token method)
	{
		this.keyword = keyword;
		this.method = method;
	}

	Token keyword;
	Token method;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitSuperExpr(this);
	}
}
class ThisExpr : Expr
{
	this(Token keyword)
	{
		this.keyword = keyword;
	}

	Token keyword;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitThisExprExpr(this);
	}
}
class Grouping : Expr
{
	this(Expr expression)
	{
		this.expression = expression;
	}

	Expr expression;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitGroupingExpr(this);
	}
}
class Literal : Expr
{
	this(Variant value)
	{
		this.value = value;
	}

	Variant value;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitLiteralExpr(this);
	}
}
class Logical : Expr
{
	this(Expr left, Token operator, Expr right)
	{
		this.left = left;
		this.operator = operator;
		this.right = right;
	}

	Expr left;
	Token operator;
	Expr right;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitLogicalExpr(this);
	}
}
class Unary : Expr
{
	this(Token operator, Expr right)
	{
		this.operator = operator;
		this.right = right;
	}

	Token operator;
	Expr right;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitUnaryExpr(this);
	}
}
class Variable : Expr
{
	this(Token name)
	{
		this.name = name;
	}

	Token name;

	override Variant accept(Visitor visitor)
	{
		return visitor.visitVariableExpr(this);
	}
}
