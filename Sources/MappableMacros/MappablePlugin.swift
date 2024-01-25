import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MappablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MappableMacro.self,
        MapMacro.self,
    ]
}
