import SwiftSyntax

extension DeclGroupSyntax {
    func accessModifiers(skip tokens: TokenSyntax...) -> DeclModifierListSyntax {
        modifiers.filter {
            let keywordText = $0.name.text
            guard !tokens.contains(where: { $0.text == keywordText }) else { return false }
            return
                keywordText == TokenSyntax.keyword(.public).text ||
                keywordText == TokenSyntax.keyword(.internal).text ||
                keywordText == TokenSyntax.keyword(.private).text ||
                keywordText == TokenSyntax.keyword(.fileprivate).text
        }
    }
    
    func containsModifier(_ modifier: Keyword) -> Bool {
        self.modifiers.contains {
            $0.name.text == TokenSyntax.keyword(.final).text
        }
    }
    
    func typeName() -> String? {
        self.as(ClassDeclSyntax.self)?.name.text ?? self.as(StructDeclSyntax.self)?.name.text
    }
}
