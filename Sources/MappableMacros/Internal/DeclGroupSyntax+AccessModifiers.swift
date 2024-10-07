import SwiftSyntax

extension DeclGroupSyntax {
    func accessModifiers(skip tokens: TokenSyntax...) -> DeclModifierListSyntax {
        modifiers.filter {
            guard let keyword = $0.name.as(TokenSyntax.self) else { return false }
            guard !tokens.contains(where: { $0.text == keyword.text }) else { return false }
            return
                keyword.text == TokenSyntax.keyword(.public).text ||
                keyword.text == TokenSyntax.keyword(.internal).text ||
                keyword.text == TokenSyntax.keyword(.private).text ||
                keyword.text == TokenSyntax.keyword(.fileprivate).text
        }
    }
}
