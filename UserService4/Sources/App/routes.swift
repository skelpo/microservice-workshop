import Fluent
import Vapor
import SendGrid

func routes(_ app: Application) throws {
    
    let currentVersion = app.grouped(.anything, "users")
    
    currentVersion.get("health") { req in
        return "All good."
    }
    
    let jwtMiddleware = app.make(JWTMiddleware.self)
    let database = app.make(Database.self)
    
    let authController = AuthController(sendGridClient: app.make(SendGridClient.self))
    let protected = currentVersion.grouped(jwtMiddleware)
    try protected.register(collection: UsersController(database: database))
    try protected.register(collection: AddressesController(database: database))
    try currentVersion.register(collection: authController)
    
    /*
    let jwtService = try container.make(JWTService.self)
    let sendGridClient = try container.make(SendGridClient.self)
    
    try root.register(collection: AuthController(jwtService: jwtService, sendGridClient: sendGridClient))*/
    
   

    /*let orderController = OrderController()
    currentVersion.post("users", use: orderController.post)
    protected.get("manage/list", use: orderController.list)
    protected.get("order", ":id", use: orderController.status)*/
    
}
