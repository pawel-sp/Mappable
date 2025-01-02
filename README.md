# Mappable

`Mappable` macro allows to generate code responsible for mapping a type to and from the other type.

## Motivation

Mapping one type to another when almost all the properties are the same requires a lot of boilerplate code. One of the examples might be creating a SwiftData type from a domain model:
```swift
struct User {
    let id: Int
    let firstName: String
    let lastName: String
}

@Model
final class UserObject {
    let id: Int
    let firstName: String
    let lastName: String
    
    init(id: Int, firstName: String, lastName: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}
```
To create `UserObject` from `User` and vice versa, the additional extensions might be required:

```swift
extension User {
    init(userObject: UserObject) {
        self.init(
            id: userObject.id,
            firstName: userObject.firstName,
            lastName: userObject.lastName
        )
    }
}

extension UserObject {
    convenience init(user: User) {
        self.init(
            id: user.id,
            firstName: user.firstName,
            lastName: user.lastName
        )
    }
}
```
Having all of that, we can now create `User` or `UserObject` by passing the other type of user model.
```swift
// User ➡️ UserObject
let user = User(id: 1, firstName: "John", lastName: "Doe")
let userObject = UserObject(user: user)

// UserObject ➡️ User
let userObject = UserObject(id: 1, firstName: "John", lastName: "Doe")
let user = User(userObject: userObject)
```
Writing such code manually is a very repetitive task. `Mappable` macro solves this issue by generating `convenience init()` and `model()` functions to a class or struct, which allows mapping it to the associated type.

## Usage

<details>
<summary>@Mappable</summary>

```swift
struct User {
    let id: Int
    let firstName: String
    let lastName: String
}

@Model
@Mappable(to: User.self)
final class UserObject {
    let id: Int
    let firstName: String
    let lastName: String
    
    init(id: Int, firstName: String, lastName: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}

🔽

@Model
final class UserObject {
    let id: Int
    let firstName: String
    let lastName: String
    
    init(id: Int, firstName: String, lastName: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }

    convenience init(model: User) {
        self.init(
            id: model.id,
            firstName: model.firstName,
            lastName: model.lastName
        )
    }

    func model() -> User {
        .init(
            id: id,
            firstName: firstName,
            lastName: lastName
        )
    }
}
```
</details>

<details>
<summary>@Mappable + custom property name</summary>

```swift
struct User {
    let id: Int
    let firstName: String
    let lastName: String
}

@Model
@Mappable(to: User.self)
final class UserObject {
    @Map("id")
    let identifier: Int
    let firstName: String
    let lastName: String
    
    init(identifier: Int, firstName: String, lastName: String) {
        self.identifier = identifier
        self.firstName = firstName
        self.lastName = lastName
    }
}

🔽

@Model
final class UserObject {
    let identifier: Int
    let firstName: String
    let lastName: String
    
    init(identifier: Int, firstName: String, lastName: String) {
        self.identifier = identifier
        self.firstName = firstName
        self.lastName = lastName
    }
    
    convenience init(model: User) {
        self.init(
            identifier: model.id,
            firstName: model.firstName,
            lastName: model.lastName
        )
    }

    func model() -> User {
        .init(
            id: identifier,
            firstName: firstName,
            lastName: lastName
        )
    }
}
```
</details>

<details>
<summary>@Mappable + custom property mapping</summary>

```swift
struct Identifier {
    let value: Int
}

struct User {
    let id: Identifier
    let firstName: String
    let lastName: String
}

@Model
@Mappable(to: User.self)
final class UserObject {
    @Map(from: \.value, to: Identifier.init(value:))
    let id: Int
    let firstName: String
    let lastName: String
    
    init(id: Int, firstName: String, lastName: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}

🔽

@Model
final class UserObject {
    let id: Int
    let firstName: String
    let lastName: String
    
    init(id: Int, firstName: String, lastName: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }

    convenience init(model: User) {
        self.init(
            id: model.id[keyPath: \.value],
            firstName: model.firstName,
            lastName: model.lastName
        )
    }

    func model() -> User {
        .init(
            id: Identifier.init(value:)(id),
            firstName: firstName,
            lastName: lastName
        )
    }
}
```
</details>

## License

`Mappable` is released under the MIT license. See the [LICENSE](LICENSE) file for more info.
