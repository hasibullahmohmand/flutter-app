class User {
  final String email;
  final String firstName;
  final String lastName;
  final String tcNumber;
  final String role;
  final String roleId; // New field to store the role ID
  final String address;

  User({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.tcNumber,
    required this.role,
    required this.roleId,  
    this.address = "",
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final address = json['address'];
    final role = json['role'];

    return User(
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      tcNumber: json['tcNumber'] ?? '',
      role: role != null ? role['name'] ?? 'Unknown' : 'Unknown',
      roleId: role != null ? role['id'] ?? 'Unknown' : 'Unknown', // Get role ID here
      address: address != null
          ? "${address['street'] ?? ''}, ${address['city'] ?? ''}, ${address['country'] ?? ''}"
          : 'No address provided',
    );
  }
}

