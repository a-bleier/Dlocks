module source.interpreter.environment;

import std.conv;
import std.variant;

import source.interpreter.scanner;
import source.interpreter.interpreter;

class Environment
{
	Variant[string] values;
	bool[string] assigned;
	Environment enclosing; //referencing the enclosing scope / env

	this()
	{
		this.enclosing = null;
	}

	this(Environment enclosing)
	{
		this.enclosing = enclosing;
	}

	void define(string name)
	{
		values[name] = Variant();
		assigned[name] = false;
	}

	void define(string name, Variant value) //we allow redefinition
	{
		values[name] = value;
		assigned[name] = true;
	}

	Variant get(Token name)
	{
		auto v = name.lexeme in values;
		if (v !is null)
		{
			if(!assigned[name.lexeme]) throw new RuntimeError(name, "Uninitialized variable '" ~ name.lexeme ~ "'.");

			return *v;
		}
		if(enclosing !is null) return enclosing.get(name);
		else
		{
			throw new RuntimeError(name, "Undefined variable '" ~ name.lexeme ~ "'.");
		}
	}

	void assign(Token name, Variant value)
	{
		auto v = name.lexeme in values;
		if (v !is null)
		{
			*v = value;
			assigned[name.lexeme] = true;
			return;
		}

		if(enclosing !is null)
		{
			enclosing.assign(name, value);
			return;
		}

		throw new RuntimeError(name,
			"Undefined variable '" ~ name.lexeme ~ "'.");
	}

}
