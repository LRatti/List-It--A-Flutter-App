// A model representing a matched receipt item with product details.
class ReceiptMatch {
  final String? productId;
  final String? productName;
  final int quantity;
  final double price;

  const ReceiptMatch({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });
}
