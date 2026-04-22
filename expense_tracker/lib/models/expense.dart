class Expense {
  final int? id;
  final double amount;
  final String? description;
  final int categoryId;
  final String date;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  Expense({
    this.id,
    required this.amount,
    this.description,
    required this.categoryId,
    required this.date,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category_id': categoryId,
      'date': date,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      description: map['description'],
      categoryId: map['category_id'],
      date: map['date'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      locationName: map['location_name'],
    );
  }
}