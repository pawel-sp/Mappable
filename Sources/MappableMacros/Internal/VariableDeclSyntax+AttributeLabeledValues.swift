import SwiftSyntax

extension VariableDeclSyntax {
    func attributeLabeledValues(at attributeName: String) -> [LabeledValue] {
        guard
            let attribute = attributes
                .first(where: { $0.as(AttributeSyntax.self)?.attributeName.description == attributeName })
                .map({ $0.as(AttributeSyntax.self) }),
            let arguments = attribute?.arguments?.as(LabeledExprListSyntax.self)
        else {
            return []
        }
        return arguments.map {
            LabeledValue(
                label: $0.label?.trimmedDescription,
                value: $0.expression.trimmedDescription
                    .removingNewLineWhitespaces()
                    .trimmedQuotes()
            )
        }
    }
}

private extension String {
    func removingNewLineWhitespaces() -> String {
        let lines = components(separatedBy: "\n")
        let updatedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        return updatedLines.joined(separator: "\n")
    }

    func trimmedQuotes() -> String {
        trimmingCharacters(in: .init(charactersIn: "\""))
    }
}

struct LabeledValue {
    let label: String?
    let value: String

    init(label: String?, value: String) {
        self.label = label
        self.value = value
    }
}

extension Array where Element == LabeledValue {
    func atLabel(_ label: String?) -> Element? {
        first(where: { $0.label == label })
    }
}
