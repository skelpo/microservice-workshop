import Fluent
import Vapor

struct OrderController {
    func list(req: Request) throws -> EventLoopFuture<[Order]> {
        return Order.query(on: req.db).all()
    }

    func post(req: Request) throws -> EventLoopFuture<OrderResponse> {
        let orderInput = try req.content.decode(OrderInput.self)
        
        let order = Order(totalAmount: orderInput.totalAmount, firstname: orderInput.firstname, lastname: orderInput.lastname, street: orderInput.street, zip: orderInput.zip, city: orderInput.city)
        
        return order.save(on: req.db).flatMap {
            var saving:[EventLoopFuture<Void>] = []
            var items:[OrderItem] = []
            
            for inputItem in orderInput.items {
                let item = OrderItem(totalAmount: inputItem.unitPrice*inputItem.quantity, unitPrice: inputItem.unitPrice, quantity: inputItem.quantity, order: order)
                saving.append(item.save(on: req.db).map {
                    items.append(item)
                })
            }
            
            return saving.flatten(on: req.make()).map {
                return OrderResponse(order: order, items: items)
            }
        }
    }

    func status(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Order.find(req.parameters.get("id"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
    }
}
