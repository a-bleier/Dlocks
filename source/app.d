module source.lox;
//TODO Next Scanning - Operators
import std.stdio;
import std.conv;
import core.stdc.stdlib;

import source.interpreter.scanner;
import source.interpreter.parser;
import source.interpreter.expr;
import source.interpreter.interpreter;
import source.interpreter.stmt;

bool hadError = false;
bool hadRuntimeError = false;
int main(string[] args)
{
    if (args.length > 2)
    {
        writeln("Usage: dlox [script]");
        exit(64);
    }
    else if (args.length == 2)
    {
        runFile(args[1]);
    }
    else
    {
        runPrompt();
    }

    return 0;
}

void runFile(string path)
{
    Interpreter interpreter = new Interpreter(false);
    File file = File(path, "r");
    string line, src;
    while ((line = file.readln()) != null)
    {
        src ~= line;
    }
    file.close();
    run(interpreter, src);
    if (hadError)
        exit(65);
    if (hadRuntimeError)
        exit(70);
}

void runPrompt()
{
    Interpreter interpreter = new Interpreter(true);
    while (true)
    {
        write(">");
        string line = readln();
        if (line == null)
            break;
        run(interpreter, line);
        hadError = false;
    }
}

void run(Interpreter interpreter, string source)
{
    auto scanner = new Scanner(source);
    auto tokens = scanner.scanTokens();

    Parser parser = new Parser(tokens);
    Stmt[] statements = parser.parse();

    // Stop if there was a syntax error.
    if (hadError)
        return;
    // writeln(new AstPrinter().print(expression));
    interpreter.interpret(statements);
}

void reportRuntimeError(RuntimeError error)
{
    writeln(error.msg ~
            "\n[line " ~ to!string(error.token.line) ~ "]");
    hadRuntimeError = true;
}

void reportError(Token token, string message)
{
    if (token.type == TokenType.EOF)
    {
        report(token.line, " at end", message);
    }
    else
    {
        report(token.line, " at '" ~ token.lexeme ~ "'", message);
    }
}

void reportError(int line, string message)
{
    report(line, "", message);
}

void report(int line, string where,
    string message)
{
    writeln(
        "[line ", line, "] Error", where, ": ", message);
    hadError = true;
}
