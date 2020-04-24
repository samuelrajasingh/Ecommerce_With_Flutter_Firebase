import 'package:firebase_database/firebase_database.dart';

class Product {
  String key;
  String name;
  int price;
  int quantity;
  String userId;

  Product(this.userId, this.name, this.price, this.quantity);

  Product.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        userId = snapshot.value["userId"],
        name = snapshot.value["name"],
        price = snapshot.value["price"],
        quantity = snapshot.value["quantity"];

  toJson() {
    return {
      "userId": userId,
      "name": name,
      "quantity": quantity,
      "price": price,
    };
  }
}
