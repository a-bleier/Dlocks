import std.stdio;
import std.file;
import std.array;
import std.string;
import std.uni;
import core.stdc.stdlib;

void main(string[] args)
{
	if (args.length != 2)
	{
		writeln("Usage: generate_ast <output directory>");
		exit(64);
	}
	string outputDir = args[1];
	defineAst(outputDir, "Expr",
		[
			"Assign   : Token name, Expr value",
			"Ternary : Expr condition, Expr left, Expr right",
			"Binary : Expr left, Token operator, Expr right",
			"Grouping : Expr expression",
			"Literal : Variant value",
			"Logical  : Expr left, Token operator, Expr right",
			"Unary : Token operator, Expr right",
			"Variable : Token name"
		],[]);
	defineAst(outputDir, "Stmt",
		[
			"Block      : Stmt[] statements",
			"Expression : Expr expression",
			"If         : Expr condition, Stmt thenBranch, Stmt elseBranch",
			"Print      : Expr expression",
			"Var : Token name, Expr initializer",
			"While      : Expr condition, Stmt body"
		],["import source.interpreter.expr;"]);
}

void defineAst(string outputDir, string baseName, string[] types, string[] imports)
{
	string path = outputDir ~ "/" ~ baseName.toLower() ~ ".d";
	File file = File(path, "w");
	file.writeln("module source.interpreter." ~ baseName.toLower() ~ ";");
	file.writeln("import source.interpreter.scanner;");
	file.writeln("import source.interpreter.parser;");
	file.writeln("import std.variant;");

	foreach(imp ; imports)
	{
		file.writeln(imp);
	}

	file.writeln("");
	file.writefln("class %s\n{", baseName);
	//TODO Write stuff here
	file.writeln("\tabstract Variant accept(Visitor visitor);");
	file.writeln("}");

	defineVisitor(file, baseName, types);

	//define type classes
	foreach (type; types)
	{
		string className = type.split(":")[0].strip(" ");
		string fields = type.split(": ")[1].strip(" ");
		defineType(file, baseName, className, fields);
	}
	file.close();
}

void defineVisitor(File file, string baseName, string[] types)
{
	file.writefln("interface Visitor \n{");
	foreach (type; types)
	{
		auto typeName = type.split(":")[0].strip(" ");
		file.writefln("\tVariant visit%s%s(%s %s);", typeName, baseName, typeName, baseName.toLower());
	}

	file.writeln("}");
}

//don't close file
void defineType(File file, string baseName, string className, string fieldList)
{
	file.writefln("class %s : %s\n{", className, baseName);

	//constructor
	file.writefln("\tthis(%s)\n\t{", fieldList);

	//store parameters in fields
	string[] fields = fieldList.split(", ");

	foreach (field; fields)
	{
		string name = field.split(" ")[1];
		file.writefln("\t\tthis.%s = %s;", name, name);
	}
	file.writeln("\t}");

	// Fields
	file.writefln("");
	foreach (field; fields)
	{
		file.writefln("\t%s;", field);
	}

	//visitor pattern impl
	file.writeln();
	file.writeln("\toverride Variant accept(Visitor visitor)\n\t{");
	file.writefln("\t\treturn visitor.visit%s%s(this);", className, baseName);
	file.writeln("\t}");
	file.writeln("}");
}
