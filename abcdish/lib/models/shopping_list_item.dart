class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.ingredientName,
    required this.quantity,
    required this.purchased,
  });

  final int id;
  final String ingredientName;
  final String? quantity;
  final bool purchased;

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      ingredientName: json['ingredientName']?.toString() ?? '',
      quantity: json['quantity']?.toString(),
      purchased: json['purchased'] == true,
    );
  }
}
