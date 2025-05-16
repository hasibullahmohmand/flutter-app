class Pending {
  final String id;
  final String imageUrl;
  final int status;
  final String uploadedAt;
  final String uploadedById;

  Pending({
    required this.id,
    required this.imageUrl,
    required this.status,
    required this.uploadedAt,
    required this.uploadedById,
  });

  factory Pending.fromJson(Map<String, dynamic> json) {
    return Pending(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      status: json['status'] as int,
      uploadedAt: json['uploadedAt'] as String,
      uploadedById: json['uploadedById'] as String,
    );
  }


}