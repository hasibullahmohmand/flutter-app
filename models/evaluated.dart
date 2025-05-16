class Evaluated{
  final String id;
  final String imageUrl;
  final int status;
  final String uploadedAt;
  final String evaluatedAt;
  final String uploadedById;
  final String receivedById;
  final int healthStatus;
  
    
  Evaluated({
    required this.id,
    required this.imageUrl,
    required this.status,
    required this.uploadedAt,
    required this.evaluatedAt,
    required this.uploadedById,
    required this.receivedById,
    required this.healthStatus,
  });
  
  factory Evaluated.fromJson(Map<String, dynamic> json) {
    return Evaluated(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      status: json['status'] as int,
      uploadedAt: json['uploadedAt'] as String,
      evaluatedAt: json['evaluatedAt'] as String,
      uploadedById: json['uploadedById'] as String,
      receivedById: json['receivedById'] as String,
      healthStatus: json['healthStatus'] as int,
    );
  }
}
