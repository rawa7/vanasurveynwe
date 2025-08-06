class Seller {
  final int id;
  final String username;

  Seller({
    required this.id,
    required this.username,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: int.tryParse(json['id'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
    };
  }

  @override
  String toString() => username;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Seller && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}