public protocol Mappable<Model> {
    associatedtype Model: Any

    init(model: Model)
    func model() -> Model
}

@attached(peer)
public macro Map<Root, Value>(
    _ propertyName: String? = nil,
    from: (Root) -> Value,
    to: (Value) -> Root
) = #externalMacro(module: "MappableMacros", type: "MapMacro")

@attached(peer)
public macro Map(
    _ propertyName: String
) = #externalMacro(module: "MappableMacros", type: "MapMacro")

@attached(member, names: named(init(model:)), named(model()))
@attached(extension, conformances: Mappable)
public macro Mappable<T>(to type: T.Type) = #externalMacro(module: "MappableMacros", type: "MappableMacro")
