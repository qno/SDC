/**
 * Copyright 2010 Bernard Helyer
 * This file is part of SDC. SDC is licensed under the GPL.
 * See LICENCE or sdc.d for more details.
 */
module sdc.ast.sdcmodule;

import std.path;

import sdc.compilererror;
import sdc.tokenstream;
import sdc.ast.base;
import sdc.ast.declaration;
import sdc.ast.attribute;


class Module : Node
{
    TokenStream tstream;   // The token stream used to create this AST tree.
    
    ModuleDeclaration moduleDeclaration;
    DeclarationDefinition[] declarationDefinitions;
}

// module QualifiedName ;
class ModuleDeclaration : Node
{
    QualifiedName name;
}

enum DeclarationDefinitionType
{
    AttributeSpecifier,
    ImportDeclaration,
    EnumDeclaration,
    ClassDeclaration,
    InterfaceDeclaration,
    AggregateDeclaration,
    Declaration,
    Constructor,
    Destructor,
    Invariant,
    UnitTest,
    StaticConstructor,
    StaticDestructor,
    SharedStaticConstructor,
    SharedStaticDestructor,
    ConditionalDeclaration,
    StaticAssert,
    TemplateDeclaration,
    TemplateMixin,
    MixinDeclaration,
    Empty,
}

enum BuildStage
{
    Unhandled,
    Deferred,
    ReadyToExpand,
    ReadyToRecurse,
    ReadyForCodegen,
    Done,
}

/**
 * A DeclarationDefinition is a top-level declaration.
 */
class DeclarationDefinition : Node
{
    DeclarationDefinitionType type;
    Node node;
    
    /* The following are for codegen purposes.
     * It's kinda icky, I know.
     */
    Attribute[] attributes;
    BuildStage buildStage;
}
