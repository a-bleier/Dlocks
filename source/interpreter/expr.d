module source.interpreter.expr;
import source.interpreter.scanner;

class Expr
{
	abstract VisitorResult accept(Visitor visitor);
}
interface Visitor 
{
	VisitorResult visitBinaryExpr(Binary expr);
	VisitorResult visitGroupingExpr(Grouping expr);
	VisitorResult visitLiteralExpr(Literal expr);
	VisitorResult visitUnaryExpr(Unary expr);
}
union VisitorResult
{
    string sRes;
    int iRes;
	Value value;

    this(string sRes)
    {
        this.sRes = sRes;
    }
    this(int iRes)
    {
        this.iRes = iRes;
    }
	this(Value value)
	{
		this.value = value;
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

	override VisitorResult accept(Visitor visitor)
	{
		return visitor.visitBinaryExpr(this);
	}
}
class Grouping : Expr
{
	this(Expr expression)
	{
		this.expression = expression;
	}

	Expr expression;

	override VisitorResult accept(Visitor visitor)
	{
		return visitor.visitGroupingExpr(this);
	}
}
class Literal : Expr
{
	this(Value value)
	{
		this.value = value;
	}

	Value value;

	override VisitorResult accept(Visitor visitor)
	{
		return visitor.visitLiteralExpr(this);
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

	override VisitorResult accept(Visitor visitor)
	{
		return visitor.visitUnaryExpr(this);
	}
}
