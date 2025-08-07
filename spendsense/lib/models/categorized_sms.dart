class CategorizedSMS {
  final String sms;
  final String category;

  CategorizedSMS({required this.sms, required this.category});

  factory CategorizedSMS.fromJson(Map<String, dynamic> json) {
    return CategorizedSMS(
      sms: json['sms'] ?? '',
      category: json['category'] ?? 'Uncategorized',
    );
  }
}
