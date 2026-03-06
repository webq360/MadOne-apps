// OrderModel.dart
//////////////////////////// for orderlist screen   /////////////////////////////////////
class OrderModel {
  final int id;
  final String orderDate;
  final String deliveryDate;
  final String paymentStatus;
  final List<OrderDetailModel> orderDetails;  // Add this line
  final double price;
  final String orderStatus;

  OrderModel({
    required this.id,
    required this.orderDate,
    required this.deliveryDate,
    required this.paymentStatus,
    required this.orderDetails,  // Add this line
    required this.price,
    required this.orderStatus,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse orderDetails from json['order_details'] and convert it to a list of OrderDetailModel
    List<OrderDetailModel> detailsList = (json['order_details'] as List)
        .map((orderDetailData) => OrderDetailModel.fromJson(orderDetailData))
        .toList();

    return OrderModel(
      id: json['id'],
      orderDate: json['order_date'],
      deliveryDate: json['delivery_date'] ?? "",
      paymentStatus: json['payment_status'],
      orderDetails: detailsList,  // Assign the parsed orderDetails
      price: double.parse(json['order_amount']),
      orderStatus: json['order_status'],
    );
  }
}

// Add OrderDetailModel.dart
////////////////////// for order details screen /////////////////////////////////////////
class OrderDetailModel {
  final int id;
  final String orderId;
  final String productId;
  final String demandQuantity;
  final String productPrice;


  OrderDetailModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.demandQuantity,
    required this.productPrice
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      demandQuantity: json['demand_quantity'],
      productPrice: json['product_price'],
    );
  }
}


class OrderDetails {
  final int id;
  final String discount;
  final String shipCharge;
  final String paymentType;
  final String paymentStatus;
  final String orderStatus;
  final String deliveryDate;
  final String orderAmount;
  final String orderQuantity;
  final String orderDate;
  final List<OrderItem> orderItems;
  final String shippingAddress;

  OrderDetails({
    required this.id,
    required this.discount,
    required this.shipCharge,
    required this.paymentType,
    required this.paymentStatus,
    required this.orderStatus,
    required this.deliveryDate,
    required this.orderAmount,
    required this.orderQuantity,
    required this.orderDate,
    required this.orderItems,
    required this.shippingAddress,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    final orderData = json['data']['order'];
    final List<dynamic> orderItemsData = json['data']['order_items'];

    return OrderDetails(
      id: orderData['id'],
      discount: orderData['discount'] ?? "",
      shipCharge: orderData['ship_charge'] ?? "",
      paymentType: orderData['payment_type'] ?? "",
      paymentStatus: orderData['payment_status'] ?? "",
      orderStatus: orderData['order_status'] ?? "",
      deliveryDate: orderData['delivery_date'] ?? "",
      orderAmount: orderData['order_amount'] ?? "",
      orderQuantity: orderData['order_quantity'] ?? "",
      orderDate: orderData['order_date'] ?? "",
      orderItems: orderItemsData
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      shippingAddress: json['data']['shipping_address'] ?? "",
    );
  }


}

class OrderItem {
  final int id;
  final String orderId;
  final String productId;
  final String demandQuantity;
  final String productPrice;
  final Product product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.demandQuantity,
    required this.productPrice,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      demandQuantity: json['demand_quantity'],
      productPrice: json['product_price'],
      product: Product.fromJson(json['product']),
    );
  }
}

class Product {
  final int id;
  final String discount;
  final String discountType;
  final String afterDiscountPrice;
  final String name;
  final String slug;
  final String image;
  final String quantity;
  final String sellPrice;

  Product({
    required this.id,
    required this.discount,
    required this.discountType,
    required this.afterDiscountPrice,
    required this.name,
    required this.slug,
    required this.image,
    required this.quantity,
    required this.sellPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      discount: json['discount'],
      discountType: json['discount_type'],
      afterDiscountPrice: json['after_discount_price'],
      name: json['name'],
      slug: json['slug'],
      image: json['image'],
      quantity: json['quantity'],
      sellPrice: json['sell_price'],
    );
  }
}
