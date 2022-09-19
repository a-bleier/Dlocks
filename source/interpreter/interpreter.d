module source.interpreter.interpreter;

import std.variant;
import std.conv;
import std.stdio;
import std.format;
import std.datetime.systime;

import core.time;

import source.interpreter.expr;
import source.interpreter.stmt;
import source.interpreter.scanner;
import source.interpreter.parser;
import source.interpreter.environment;
import source.interpreter.callable;
import source.lox;

class Interpreter : source.interpreter.expr.Visitor, source.interpreter.stmt.Visitor
{

    Environment globals = new Environment();
    private Environment environment;
    private bool replSupport;
    private bool breakFlag = false;
    private int[Expr] locals;

    void test()
    {

    }

    this(bool replSupport)
    {
        this.replSupport = replSupport;
        this.environment = globals;
        globals.define("clock", Variant(
                new class LoxCallable
            {
                int arity()
                {
                    return 0;}

                    //return time in sec
                    public Variant call(Interpreter interpreter, Variant[] args)
                    {
                        return Variant(to!double(Clock.currTime().toTimeVal.tv_sec));
                    }
                }

        ));
    }

    void interpret(Stmt[] statements)
    {
    try
        {
            foreach (statement; statements)
            {
                execute(statement);
            }
        }
        catch (RuntimeError error)
        {
            reportRuntimeError(error);
        }
    }

    void executeBlock(Stmt[] statements, Environment environment)
    {
        Environment previous = this.environment;
        try
        {
            this.environment = environment;

            foreach (stmt; statements)
            {
                execute(stmt);
                if (breakFlag)
                    break;
            }
        }
        finally
        {
            this.environment = previous;
        }
    }

    private void execute(Stmt s)
    {
        s.accept(this);
    }

    public void resolve(Expr expr, int depth) 
    {
        locals[expr] = depth;
    }

    public Variant visitFunctionStmt(Function stmt)
    {
        LoxFunction lfunction = new LoxFunction(stmt, environment);
        environment.define(stmt.name.lexeme, Variant(lfunction));
        return Variant();
    }

    public Variant visitBlockStmt(Block stmt)
    {
        executeBlock(stmt.statements, new Environment(environment));
        return Variant();
    }

    public Variant visitAssignExpr(Assign expr)
    {
        Variant value = evaluate(expr.value);
        auto dist = expr in locals;
        if (dist !is null)
        {
            environment.assignAt(*dist, expr.name, value);
        }
        else
        {
            globals.assign(expr.name, value);
        }
        environment.assign(expr.name, value);
        return value;
    }

    public Variant visitIfStmt(If stmt)
    {
        if (isTruthy(evaluate(stmt.condition)))
        {
            execute(stmt.thenBranch);
        }
        else if (stmt.elseBranch !is null)
        {
            execute(stmt.elseBranch);
        }
        return Variant();
    }

    public Variant visitReturnStmt(Return stmt)
    {
        Variant value = Variant();
        if(stmt.value !is null) value = evaluate(stmt.value);

        throw new ReturnVal(value);
        return Variant();
    }

    public Variant visitWhileStmt(While stmt)
    {
        while (isTruthy(evaluate(stmt.condition)))
        {
            execute(stmt.body);
            if (breakFlag)
            {
                breakFlag = false;
                break;
            }
        }
        return Variant();
    }

    public Variant visitBreakStmt(Break stmt)
    {
        this.breakFlag = true;
        return Variant();
    }

    Variant visitVarStmt(Var stmt)
    {
        Variant value;
        if (stmt.initializer !is null)
        {
            value = evaluate(stmt.initializer);
            environment.define(stmt.name.lexeme, value);
        }
        else
        {
            environment.define(stmt.name.lexeme);
        }
        return Variant();
    }

    Variant visitExpressionStmt(Expression stmt)
    {
        Variant value = evaluate(stmt.expression);
        if (replSupport)
            writeln(stringify(value));
        return Variant();
    }

    Variant visitPrintStmt(Print stmt)
    {
        Variant value = evaluate(stmt.expression);
        writeln(stringify(value));
        return Variant();
    }

    public Variant visitLogicalExpr(Logical expr)
    {
        Variant left = evaluate(expr.left);

        if (expr.operator.type == TokenType.OR)
        {
            if (isTruthy(left))
                return left;
        }
        else
        {
            if (!isTruthy(left))
                return left;
        }

        return evaluate(expr.right);
    }

    Variant visitVariableExpr(Variable expr)
    {
        return lookUpVariable(expr.name, expr);
    }

    private Variant lookUpVariable(Token name, Expr expr)
    {
        auto dist = expr in locals;
        if(dist !is null)
        {
            return environment.getAt(*dist, name.lexeme);
        }
        else
        {
            return globals.get(name);
        }
    }

    Variant visitLiteralExpr(Literal expr)
    {
        return expr.value;
    }

    Variant visitGroupingExpr(Grouping expr)
    {
        return evaluate(expr.expression);
    }

    Variant visitTernaryExpr(Ternary ternary)
    {
        return Variant();
    }

    Variant visitUnaryExpr(Unary expr)
    {
        Variant right = evaluate(expr.right);
        Variant result;
        switch (expr.operator.type)
        {
        case TokenType.MINUS:
            checkNumberOperand(expr.operator, right);
            result = Variant(-1 * right.get!(double));
            break;
        case TokenType.BANG:
            result = Variant(!isTruthy(right));
            break;
        default:
            break;
        }
        return result;
    }

    Variant visitCallExpr(Call expr)
    {
        Variant callee = evaluate(expr.callee);

        Variant[] arguments;
        foreach (arg; expr.arguments)
        {
            arguments ~= evaluate(arg);
        }

        //is the callee callable ?
        if (!callee.convertsTo!(LoxCallable))
            throw new RuntimeError(expr.paren, "Can only call functions and classes");
        LoxCallable loxFunction = callee.get!(LoxCallable);

        //Arity: Number of expected function arguments
        if (arguments.length != loxFunction.arity())
        {
            throw new RuntimeError(expr.paren, format("Expected %d arguments but got %d.",
                    loxFunction.arity(), arguments.length));
        }
        return loxFunction.call(this, arguments);
    }

    Variant visitBinaryExpr(Binary expr)
    {
        Variant right = evaluate(expr.right);
        Variant left = evaluate(expr.left);
        Variant result;
        switch (expr.operator.type)
        {
        case TokenType.MINUS:
            checkNumberOperand(expr.operator, right, left);
            result = left.get!(double) - right.get!(double);
            break;
        case TokenType.SLASH:
            checkNumberOperand(expr.operator, right, left);
            if (right.get!(double) == 0.0)
                throw new RuntimeError(expr.operator, "Division by zero");
            result = left.get!(double) / right.get!(double);
            break;
        case TokenType.STAR:
            checkNumberOperand(expr.operator, right, left);
            result = left.get!(double) * right.get!(double);
            break;
        case TokenType.PLUS:
            if (right.peek!(double) !is null && left.peek!(
                    double) !is null)
            {
                checkNumberOperand(expr.operator, right, left);
                result = left.get!(double) + right.get!(double);
            }
            else if (right.peek!(string) != null && left.peek!(string) != null)
            {
                result = left.get!(string) ~ right.get!(string);
            }
            else if (right.peek!(string) != null && left.peek!(double) != null)
            {
                result = left.coerce!(string) ~ right.coerce!(string);
            }
            else if (right.peek!(double) != null && left.peek!(string) != null)
            {
                result = left.coerce!(string) ~ right.coerce!(string);
            }
            else
            {
                throw new RuntimeError(expr.operator, "Operands must be of type number or string");
            }
            break;
        case TokenType.GREATER:
            checkNumberOperand(expr.operator, right, left);
            result = left.get!(double) > right.get!(double);
            break;
        case TokenType.GREATER_EQUAL:
            checkNumberOperand(expr.operator, right, left);
            result = left.get!(double) >= right.get!(double);
            break;
        case TokenType.LESS:
            checkNumberOperand(expr.operator, right, left);
            result = left.get!(double) < right.get!(double);
            break;
        case TokenType.LESS_EQUAL:
            checkNumberOperand(expr.operator, right, left);
            result = left.get!(double) <= right.get!(double);
            break;
        case TokenType.BANG_EQUAL:
            result = !isEqual(left, right);
            break;
        case TokenType.EQUAL_EQUAL:
            result = isEqual(left, right);
            break;
            // case TokenType.QUESTION_MARK:
            // 	result = 
        default:
            break;
        }
        return result;
    }

    Variant evaluate(Expr expr)
    {
        return expr.accept(this);
    }

    private bool isTruthy(Variant val)
    {
        if (!val.hasValue())
            return false;
        if (val.peek!(bool) !is null)
            return val.get!(bool);
        return true;
    }

    private bool isEqual(Variant left, Variant right)
    {
        return left == right;
    }

    private void checkNumberOperand(Token operator, Variant operand)
    {
        if (operand.peek!(double) != null)
            return;
        throw new RuntimeError(operator, "Operand must be a number.");
    }

    private void checkNumberOperand(Token operator, Variant operand_left, Variant operand_right)
    {
        if (operand_left.peek!(double) != null && operand_right.peek!(double) != null)
            return;
        throw new RuntimeError(operator, "Operands must be numbers.");
    }

    private string stringify(Variant value)
    {
        if (!value.hasValue())
            return "nil";

        if (value.peek!(double) != null)
        {
            auto text = to!string(*value.peek!(double));
            if (text.length > 2 && text[$ - 2 .. $] == ".0")
            {
                text = text[$ - 2 .. $];
            }
            return text;
        }

        return value.coerce!(string);
    }

}

class RuntimeError : Exception
{
    Token token;
    this(Token token, string message) pure nothrow @nogc @safe
    {
        super(message, __FILE__, __LINE__, null);
        this.token = token;
    }
}
