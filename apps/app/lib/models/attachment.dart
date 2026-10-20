class Attachment {
  const Attachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.url,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String url;

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'url': url,
    };
  }
}
