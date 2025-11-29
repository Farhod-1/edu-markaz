class Room {
  final String id;
  final String name;
  final int capacity;
  final String? description;
  final String organizationId;

  Room({
    required this.id,
    required this.name,
    required this.capacity,
    this.description,
    required this.organizationId,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      capacity: json['capacity'] as int? ?? 0,
      description: json['description'] as String?,
      organizationId: json['organizationId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'capacity': capacity,
      'description': description,
      'organizationId': organizationId,
    };
  }
}
