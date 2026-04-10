class Category {
  final int? id;
  final String name;
  final String? description;

  Category({
    this.id,
    required this.name,
    this.description,
  });

  // Convert a Category into a Map (for saving to DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  // Create a Category from a Map (for reading from DB)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }
}