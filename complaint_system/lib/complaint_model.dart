enum ComplaintStatus { pending, solved, rejected }

class Complaint {
  final String id;
  final String title;
  final String description;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      status: ComplaintStatus.values.firstWhere(
            (e) => e.toString().split('.').last == (json['status'] ?? 'pending'),
        orElse: () => ComplaintStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sender_id': senderId,
      'sender_name': senderName,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Complaint copyWith({
    String? id,
    String? title,
    String? description,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    ComplaintStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}