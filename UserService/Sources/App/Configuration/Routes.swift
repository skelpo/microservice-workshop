import Routing
import Vapor
import JWTMiddleware
import SendGrid

public func routes(_ router: Router, _ container: Container) throws {
    let root = router.grouped(any, "users")
    
    root.get("health") { _ in
        return "all good"
    }
    
    let jwtService = try container.make(JWTService.self)
    let sendGridClient = try container.make(SendGridClient.self)
    
    try root.register(collection: AuthController(jwtService: jwtService, sendGridClient: sendGridClient))
    try root.grouped(JWTAuthenticatableMiddleware<User>()).register(collection: UsersController())
    try root.grouped("addresses").grouped(JWTAuthenticatableMiddleware<User>()).register(collection: AddressesController())
}
