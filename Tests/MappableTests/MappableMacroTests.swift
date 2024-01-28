import MappableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let testMacros: [String: Macro.Type] = [
    "Mappable": MappableMacro.self,
    "Map": MapMacro.self,
]

final class MappableMacroTests: XCTestCase {
    func testDefaultMacro() throws {
        assertMacroExpansion(
            """
            @Mappable(to: Bar.self)
            class Foo {
                let value: Int

                init(value: Int) {
                    self.value = value
                }
            }
            struct Bar {
                let value: Int
            }
            """,
            expandedSource:
            """
            class Foo {
                let value: Int

                init(value: Int) {
                    self.value = value
                }

                convenience init(model: Bar) {
                    self.init(
                        value: model.value
                    )
                }

                func model() -> Bar {
                    .init(
                        value: value
                    )
                }
            }
            struct Bar {
                let value: Int
            }
            """,
            macros: testMacros
        )
    }

    func testMapMacroWithFromClosure() throws {
        assertMacroExpansion(
            """
            @Mappable(to: Bar.self)
            class Foo {
                let value1: Int
                @Map(from: { String($0) }, to: { Int($0) ?? 0 })
                let value2: String

                init(value1: Int, value2: String) {
                    self.value1 = value1
                    self.value2 = value2
                }
            }
            struct Bar {
                let value1: Int
                let value2: Int
            }
            """,
            expandedSource:
            """
            class Foo {
                let value1: Int
                let value2: String

                init(value1: Int, value2: String) {
                    self.value1 = value1
                    self.value2 = value2
                }

                convenience init(model: Bar) {
                    self.init(
                        value1: model.value1,
                        value2: {
                            String($0)
                        }(model.value2)
                    )
                }

                func model() -> Bar {
                    .init(
                        value1: value1,
                        value2: {
                            Int($0) ?? 0
                        }(value2)
                    )
                }
            }
            struct Bar {
                let value1: Int
                let value2: Int
            }
            """,
            macros: testMacros
        )
    }

    func testMapMacroWithFromKeyPath() throws {
        assertMacroExpansion(
            """
            @Mappable(to: Bar.self)
            class Foo {
                let value1: Int
                @Map(from: \\.value, to: Baz.init)
                let value2: Int

                init(value1: Int, value2: String) {
                    self.value1 = value1
                    self.value2 = value2
                }
            }
            struct Bar {
                let value: Int
            }
            struct Baz {
                let value: Int
            }
            """,
            expandedSource:
            """
            class Foo {
                let value1: Int
                let value2: Int

                init(value1: Int, value2: String) {
                    self.value1 = value1
                    self.value2 = value2
                }

                convenience init(model: Bar) {
                    self.init(
                        value1: model.value1,
                        value2: model.value2[keyPath: \\.value]
                    )
                }

                func model() -> Bar {
                    .init(
                        value1: value1,
                        value2: Baz.init(value2)
                    )
                }
            }
            struct Bar {
                let value: Int
            }
            struct Baz {
                let value: Int
            }
            """,
            macros: testMacros
        )
    }

    func testMapMacroWithCustomPropertyName() throws {
        assertMacroExpansion(
            """
            @Mappable(to: Bar.self)
            class Foo {
                @Map("val")
                let value: Int

                init(value: Int) {
                    self.value = value
                }
            }
            struct Bar {
                let val: Int
            }
            """,
            expandedSource:
            """
            class Foo {
                let value: Int

                init(value: Int) {
                    self.value = value
                }

                convenience init(model: Bar) {
                    self.init(
                        value: model.val
                    )
                }

                func model() -> Bar {
                    .init(
                        val: value
                    )
                }
            }
            struct Bar {
                let val: Int
            }
            """,
            macros: testMacros
        )
    }

    func testMapMacroWithCustomPropertyNameAndClosures() throws {
        assertMacroExpansion(
            """
            @Mappable(to: Bar.self)
            class Foo {
                let value1: Int
                @Map("customValue2", from: { String($0) }, to: { Int($0) ?? 0 })
                let value2: String

                init(value1: Int, value2: String) {
                    self.value1 = value1
                    self.value2 = value2
                }
            }
            struct Bar {
                let value1: Int
                let customValue2: Int
            }
            """,
            expandedSource:
            """
            class Foo {
                let value1: Int
                let value2: String

                init(value1: Int, value2: String) {
                    self.value1 = value1
                    self.value2 = value2
                }

                convenience init(model: Bar) {
                    self.init(
                        value1: model.value1,
                        value2: {
                            String($0)
                        }(model.customValue2)
                    )
                }

                func model() -> Bar {
                    .init(
                        value1: value1,
                        customValue2: {
                            Int($0) ?? 0
                        }(value2)
                    )
                }
            }
            struct Bar {
                let value1: Int
                let customValue2: Int
            }
            """,
            macros: testMacros
        )
    }

    func testMapMacroWithMultipleLines() throws {
        assertMacroExpansion(
            """
            @Mappable(to: Bar.self)
            class Foo {
                let value1: Int
                @Map(
                    from: {
                        let number = $0
                        let numberString = String(number)
                        return numberString
                    },
                    to: {
                        let text = $0
                        let number = Int(text) ?? 0
                        return number
                    }
                )
                let value2: String

                init(value1: Int, value2: String) {
                    self.value1 = value1
                    self.value2 = value2
                }
            }
            struct Bar {
                let value1: Int
                let value2: Int
            }
            """,
            expandedSource:
            """
            class Foo {
                let value1: Int
                let value2: String

                init(value1: Int, value2: String) {
                    self.value1 = value1
                    self.value2 = value2
                }

                convenience init(model: Bar) {
                    self.init(
                        value1: model.value1,
                        value2: {
                            let number = $0
                            let numberString = String(number)
                            return numberString
                        }(model.value2)
                    )
                }

                func model() -> Bar {
                    .init(
                        value1: value1,
                        value2: {
                            let text = $0
                            let number = Int(text) ?? 0
                            return number
                        }(value2)
                    )
                }
            }
            struct Bar {
                let value1: Int
                let value2: Int
            }
            """,
            macros: testMacros
        )
    }
}
