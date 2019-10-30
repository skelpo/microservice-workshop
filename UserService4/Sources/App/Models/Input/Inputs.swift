import Vapor

struct AddressInput: Content {
    let street: String
    let city: String
    let zip: String
}
struct NewUserInput: Content {
    let firstname: String
    let lastname: String
    let email: String
    let password: String
}
struct RenewAccessTokenInput: Content {
    let refreshToken: String
}
struct EditUserInput: Content {
    let firstname: String?
    let lastname: String?
}
struct LoginInput: Content {
    let email: String
    let password: String
}
