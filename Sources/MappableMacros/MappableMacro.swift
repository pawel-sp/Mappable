import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MappableMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case onlyApplicableToStructOrClass
        case missingTypeDefined
        case emptyPropertyName

        public var description: String {
            switch self {
            case .onlyApplicableToStructOrClass:
                "@Mappable can be applied only to class or struct declaration."
            case .missingTypeDefined:
                "@Mappable requires type defined."
            case .emptyPropertyName:
                "@Map custom property name cannot be empty."
            }
        }
    }
}

extension MappableMacro: MemberMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in _: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            throw Error.onlyApplicableToStructOrClass
        }

        let args: LabeledExprListSyntax = {
            if case let .argumentList(args) = node.arguments { args }
            else { [] }
        }()
        guard
            let typeSyntax = args.first,
            let typeExpression = typeSyntax.expression.as(MemberAccessExprSyntax.self)?.base
        else {
            throw Error.missingTypeDefined
        }
        let accessModifiers = declaration.accessModifiers(skip: TokenSyntax.keyword(.private))
        let mappableType = typeExpression.description
        let variablesDecl = declaration.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }

        return try [
            .init(
                initFromModelDecl(
                    accessModifiers: accessModifiers,
                    isRequired: !declaration.containsModifier(.final),
                    mappableType: mappableType,
                    variablesDecl: variablesDecl
                )
            ),
            .init(
                makeModelFuncDecl(
                    accessModifiers: accessModifiers,
                    mappableType: mappableType,
                    variablesDecl: variablesDecl
                )
            ),
        ]
    }

    // MARK: Init from model

    private static func initFromModelDecl(
        accessModifiers: DeclModifierListSyntax,
        isRequired: Bool,
        mappableType: String,
        variablesDecl: [VariableDeclSyntax]
    ) throws -> InitializerDeclSyntax {
        try .init(
            modifiers: accessModifiers +
                (isRequired ? [DeclModifierSyntax(name: TokenSyntax.keyword(.required))] : []) +
                [DeclModifierSyntax(name: TokenSyntax.keyword(.convenience))],
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        FunctionParameterSyntax(
                            firstName: TokenSyntax(stringLiteral: "model"),
                            type: TypeSyntax(stringLiteral: mappableType)
                        )
                    }
                )
            ),
            body: CodeBlockSyntax {
                try FunctionCallExprSyntax(
                    calledExpression: ExprSyntax("self.init"),
                    leftParen: .leftParenToken(),
                    arguments: initFromModelArguments(variablesDecl: variablesDecl),
                    rightParen: .rightParenToken(leadingTrivia: .newline)
                )
            }
        )
    }

    private static func initFromModelArguments(variablesDecl: [VariableDeclSyntax]) throws -> LabeledExprListSyntax {
        try .init {
            for variableDecl in variablesDecl {
                if let argument = try initFromModelArgument(variableDecl: variableDecl) {
                    argument
                }
            }
        }
    }

    private static func initFromModelArgument(variableDecl: VariableDeclSyntax) throws -> LabeledExprSyntax? {
        guard let variableName = variableDecl.bindings.first?.pattern.trimmedDescription else { return nil }

        let mapLabeledValues = variableDecl.attributeLabeledValues(at: "Map")
        let customPropertyName = mapLabeledValues.atLabel(nil)?.value
        let fromAttributeValue = mapLabeledValues.atLabel("from")?.value

        if let customPropertyName, customPropertyName.isEmpty {
            throw Error.emptyPropertyName
        }

        return .init(
            leadingTrivia: .newline,
            label: TokenSyntax(stringLiteral: variableName),
            colon: .colonToken(),
            expression: {
                switch (customPropertyName, fromAttributeValue) {
                case let (customName, .none):
                    ExprSyntax(stringLiteral: "model.\(customName ?? variableName)")
                case let (customName, .some(labeledValue)) where labeledValue.hasPrefix("\\"):
                    ExprSyntax(stringLiteral: "model.\(customName ?? variableName)[keyPath: \(labeledValue)]")
                case let (customName, .some(labeledValue)):
                    ExprSyntax(stringLiteral: "\(labeledValue)(model.\(customName ?? variableName))")
                }
            }()
        )
    }

    // MARK: To model

    private static func makeModelFuncDecl(
        accessModifiers: DeclModifierListSyntax,
        mappableType: String,
        variablesDecl: [VariableDeclSyntax]
    ) throws -> FunctionDeclSyntax {
        try .init(
            modifiers: accessModifiers,
            name: TokenSyntax(stringLiteral: "model"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: FunctionParameterListSyntax()),
                returnClause: ReturnClauseSyntax(type: TypeSyntax(stringLiteral: mappableType))
            ),
            body: CodeBlockSyntax {
                try FunctionCallExprSyntax(
                    calledExpression: ExprSyntax(".init"),
                    leftParen: .leftParenToken(),
                    arguments: makeModelFuncArguments(variablesDecl: variablesDecl),
                    rightParen: .rightParenToken(leadingTrivia: .newline)
                )
            }
        )
    }

    private static func makeModelFuncArguments(variablesDecl: [VariableDeclSyntax]) throws -> LabeledExprListSyntax {
        try .init {
            for variableDecl in variablesDecl {
                if let argument = try makeModelFuncArgument(variableDecl: variableDecl) {
                    argument
                }
            }
        }
    }

    private static func makeModelFuncArgument(variableDecl: VariableDeclSyntax) throws -> LabeledExprSyntax? {
        guard let variableName = variableDecl.bindings.first?.pattern.trimmedDescription else { return nil }

        let mapLabeledValues = variableDecl.attributeLabeledValues(at: "Map")
        let customPropertyName = mapLabeledValues.atLabel(nil)?.value
        let toAttributeValue = mapLabeledValues.atLabel("to")?.value

        if let customPropertyName, customPropertyName.isEmpty {
            throw Error.emptyPropertyName
        }

        return .init(
            leadingTrivia: .newline,
            label: TokenSyntax(stringLiteral: customPropertyName ?? variableName),
            colon: .colonToken(),
            expression: {
                if let toAttributeValue {
                    ExprSyntax(stringLiteral: toAttributeValue + "(\(variableName))")
                } else {
                    ExprSyntax(stringLiteral: variableName)
                }
            }()
        )
    }
}

extension MappableMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard
            (declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self)),
            let extendedType = declaration.typeName()
        else {
            throw Error.onlyApplicableToStructOrClass
        }
        let extensionDecl = ExtensionDeclSyntax(
            extendedType: TypeSyntax(stringLiteral: extendedType),
            inheritanceClause: .init(inheritedTypes: .init(arrayLiteral: .init(type: TypeSyntax("Mappable")))),
            memberBlockBuilder: {}
        )
        return [extensionDecl]
    }
}
