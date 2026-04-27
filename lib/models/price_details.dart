import 'dart:convert';

class PriceDetails {
  final double value;
  final String? period;
  final double? securityDeposit;
  final bool isFree;
  PriceDetails({
    required this.value,
    this.period,
    this.securityDeposit,
    required this.isFree,
  });

  PriceDetails copyWith({
    double? value,
    String? period,
    double? securityDeposit,
    bool? isFree,
  }) {
    return PriceDetails(
      value: value ?? this.value,
      period: period ?? this.period,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      isFree: isFree ?? this.isFree,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'period': period,
      'securityDeposit': securityDeposit,
      'isFree': isFree,
    };
  }

  factory PriceDetails.fromMap(Map<String, dynamic> map) {
    return PriceDetails(
      value: map['value']?.toDouble() ?? 0.0,
      period: map['period'],
      securityDeposit: map['securityDeposit']?.toDouble(),
      isFree: map['isFree'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory PriceDetails.fromJson(String source) =>
      PriceDetails.fromMap(json.decode(source));
}
