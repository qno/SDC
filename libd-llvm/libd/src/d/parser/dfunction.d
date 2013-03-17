module d.parser.dfunction;

import d.ast.dfunction;

import d.parser.base;
import d.parser.dtemplate;
import d.parser.expression;
import d.parser.statement;
import d.parser.type;
import d.parser.util;

import d.ast.declaration;
import d.ast.dtemplate;
import d.ast.statement;

/**
 * Parse constructor.
 */
auto parseConstructor(TokenRange)(ref TokenRange trange) if(isTokenRange!TokenRange) {
	auto location = trange.front.location;
	trange.match(TokenType.This);
	
	return trange.parseFunction!(ConstructorDeclaration)(location);
}

/**
 * Parse destructor.
 */
auto parseDestructor(TokenRange)(ref TokenRange trange) if(isTokenRange!TokenRange) {
	auto location = trange.front.location;
	trange.match(TokenType.Tilde);
	trange.match(TokenType.This);
	
	return trange.parseFunction!(DestructorDeclaration)(location);
}

/**
 * Parse function declaration, starting with parameters.
 * This allow to parse function as well as constructor or any special function.
 * Additionnal parameters are used to construct the function.
 */
Declaration parseFunction(FunctionDeclarationType = FunctionDeclaration, TokenRange, U... )(ref TokenRange trange, Location location, U arguments) if(isTokenRange!TokenRange) {
	// Function declaration.
	bool isVariadic;
	TemplateParameter[] tplParameters;
	
	// Check if we have a function template
	auto lookahead = trange.save;
	lookahead.popMatchingDelimiter!(TokenType.OpenParen)();
	if(lookahead.front.type == TokenType.OpenParen) {
		tplParameters = trange.parseTemplateParameters();
	}
	
	auto parameters = trange.parseParameters(isVariadic);
	
	// If it is a template, it can have a constraint.
	if(tplParameters.ptr) {
		if(trange.front.type == TokenType.If) {
			trange.parseConstraint();
		}
	}
	
	// TODO: parse function attributes
	// Parse function attributes
	functionAttributeLoop : while(1) {
		switch(trange.front.type) {
			case TokenType.Pure, TokenType.Const, TokenType.Immutable, TokenType.Inout, TokenType.Shared, TokenType.Nothrow :
				trange.popFront();
				break;
			
			case TokenType.At :
				trange.popFront();
				trange.match(TokenType.Identifier);
				break;
			
			default :
				break functionAttributeLoop;
		}
	}
	
	// TODO: parse contracts.
	// Skip contracts
	switch(trange.front.type) {
		case TokenType.In, TokenType.Out :
			trange.popFront();
			trange.parseBlock();
			
			switch(trange.front.type) {
				case TokenType.In, TokenType.Out :
					trange.popFront();
					trange.parseBlock();
					break;
				
				default :
					break;
			}
			
			trange.match(TokenType.Body);
			break;
		
		case TokenType.Body :
			// Body without contract is just skipped.
			trange.popFront();
			break;
		
		default :
			break;
	}
	
	BlockStatement fbody;
	switch(trange.front.type) {
		case TokenType.Semicolon :
			location.spanTo(trange.front.location);
			trange.popFront();
			
			break;
		
		case TokenType.OpenBrace :
			fbody = trange.parseBlock();
			location.spanTo(fbody.location);
			
			break;
		
		default :
			// TODO: error.
			trange.match(TokenType.Begin);
			assert(0);
	}
	
	auto fun = new FunctionDeclarationType(location, arguments, parameters, isVariadic, fbody);
	
	if(tplParameters.ptr) {
		return new TemplateDeclaration(location, fun.name, tplParameters, [fun]);
	} else {
		return fun;
	}
}

/**
 * Parse function and delegate parameters.
 */
auto parseParameters(TokenRange)(ref TokenRange trange, out bool isVariadic) {
	trange.match(TokenType.OpenParen);
	
	Parameter[] parameters;
	
	switch(trange.front.type) {
		case TokenType.CloseParen :
			break;
		
		case TokenType.TripleDot :
			trange.popFront();
			isVariadic = true;
			break;
		
		default :
			parameters ~= trange.parseParameter();
			
			while(trange.front.type == TokenType.Comma) {
				trange.popFront();
				
				if(trange.front.type == TokenType.TripleDot) {
					goto case TokenType.TripleDot;
				}
				
				parameters ~= trange.parseParameter();
			}
	}
	
	trange.match(TokenType.CloseParen);
	
	return parameters;
}

private auto parseParameter(TokenRange)(ref TokenRange trange) {
	bool isReference;
	
	// TODO: parse storage class
	ParseStorageClassLoop: while(1) {
		switch(trange.front.type) {
			case TokenType.In, TokenType.Out, TokenType.Lazy :
				trange.popFront();
				break;
			
			case TokenType.Ref :
				trange.popFront();
				isReference = true;
				
				break;
			
			default :
				break ParseStorageClassLoop;
		}
	}
	
	auto type = trange.parseType();
	
	Parameter param;
	if(trange.front.type == TokenType.Identifier) {
		auto location = type.location;
		
		string name = trange.front.value;
		trange.popFront();
		
		if(trange.front.type == TokenType.Assign) {
			trange.popFront();
			
			auto expression = trange.parseAssignExpression();
			
			location.spanTo(expression.location);
			return new InitializedParameter(location, name, type, expression);
		}
		
		param = new Parameter(location, name, type);
	} else {
		param = new Parameter(type.location, type);
	}
	
	param.isReference = isReference;
	
	return param;
}
