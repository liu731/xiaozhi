class StorageMessage {
  final String id;

  final String text;

  final bool sendByMe;

  final DateTime createdAt;

  StorageMessage({
    required this.id,
    required this.text,
    required this.sendByMe,
    required this.createdAt,
  });

  factory StorageMessage.fromJson(Map<String, dynamic> json) {
    return StorageMessage(
      id: json['id'],
      text: json['data'],
      sendByMe: 1 == json['send_by_me'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': text,
      'send_by_me': sendByMe ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
