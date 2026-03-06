// class CartItem {
//   final int id;
//   String image;
//   String name; // Change 'title' to 'name'
//   num sell_price;
//   double after_discount_price;
//   String subtitle;
//   int quantity;
//   bool addedFromProductDetails;
//
//   CartItem({
//     required this.id,
//     required this.image,
//     required this.name, // Change 'title' to 'name'
//     required this.sell_price,
//     required this.after_discount_price,
//     required this.subtitle,
//     required this.quantity,
//     this.addedFromProductDetails = false,
//   });
//
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'image': image,
//       'name': name, // Change 'title' to 'name'
//       'sell_price': sell_price,
//       'after_discount_price': after_discount_price,
//       'subtitle': subtitle,
//       'quantity': quantity,
//       'addedFromProductDetails': addedFromProductDetails,
//     };
//   }
// }
class CartItem {
  final int id;
  String image;
  String name;
  String company_name;
  num sell_price;
  double after_discount_price;
  String subtitle;
  int quantity;
  bool addedFromProductDetails;

  CartItem({
    required this.id,
    required this.image,
    required this.name,
    required this.company_name,
    required this.sell_price,
    required this.after_discount_price,
    required this.subtitle,
    required this.quantity,
    this.addedFromProductDetails = false,
  });

  // Factory constructor to parse JSON into CartItem object
  factory CartItem.fromJson(Map<String, dynamic> json) {
    String company_name = json['company_name'] != null ? json['company_name'] : 'Unknown';
    print('Company Name: $company_name');
    print('Brand JSON: ${json['brand']}');
    print('Brand Name: ${json['brand'] != null ? json['brand']['brand_name'] : 'Unknown'}');
    return CartItem(
      id: json['id'],
      image: json['image'],
      name: json['name'],
      company_name: company_name,
      //company_name: json['brand'] != null ? json['brand']['brand_name'] ?? 'Unknown' : 'Unknown',
      sell_price: json['sell_price'],
      after_discount_price: json['after_discount_price'],
      subtitle: json['subtitle'],
      quantity: json['quantity'],
      addedFromProductDetails: json['addedFromProductDetails'] ?? false,
    );
  }

  // Convert CartItem object to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image': image,
      'name': name,
      'company_name' : company_name,
      'sell_price': sell_price,
      'after_discount_price': after_discount_price,
      'subtitle': subtitle,
      'quantity': quantity,
      'addedFromProductDetails': addedFromProductDetails,
    };
  }

  // Convert CartItem object to JSON
  Map<String, dynamic> toJson() => toMap();
}

