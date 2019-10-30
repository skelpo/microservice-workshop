import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    let currentVersion = app.grouped(.anything, "orders")
    
    currentVersion.get("health") { req in
        return "All good."
    }
    
    let jwtMiddleware = app.make(JWTMiddleware.self)
    
    let protected = currentVersion.grouped(jwtMiddleware)

    let orderController = OrderController()
    currentVersion.post("order", use: orderController.post)
    protected.get("manage/list", use: orderController.list)
    protected.get("order", ":id", use: orderController.status)
}
