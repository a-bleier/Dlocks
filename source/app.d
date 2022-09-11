module source.lox;
//TODO Next Scanning - Operators
import std.stdio;
import core.stdc.stdlib;

import source.interpreter.scanner;
import source.interpreter.astprinter;

bool hadError = false;
int main(string[] args)
{
	printTest();
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
	File file = File(path, "r");
	string line, src;
	while ((line = file.readln()) != null)
	{
		src ~= line;
	}
	file.close();
	run(src);
	if(hadError) exit(65);
}

void runPrompt()
{
	while (true)
	{
		write(">");
		string line = readln();
		if (line == null)
			break;
		run(line);
		hadError = false;
	}
}

void run(string source)
{
	auto scanner = new Scanner(source);
	auto tokens = scanner.scanTokens();

	foreach(token ; tokens)
	{
		writeln(token);
	}
}

void error(int line, string message)
{
	report(line, "", message);
}

void report(int line, string where,
	string message)
{
	writeln(
		"[line " , line , "] Error" , where , ": " , message);
	hadError = true;
}
