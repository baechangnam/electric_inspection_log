// lib/models/board_item.dart
class BoardItem {
  final int id;
  final String consumerName;
  final String facilityLocation;
  final String representativeName;
  final String phoneNumber;
  final String incomingPrimaryVoltage;
  final String incomingSecondaryVoltage;
  final String incomingCapacity;
  final String generationPrimaryVoltage;
  final String generationSecondaryVoltage;
  final String generationCapacity;
  final String solarVoltage;
  final String solarCapacity;
  final String storageVoltage;
  final String storageCapacity;
  final String weight;
  final String supervisorName;
  final String inspectorName;
  final String feeWithTax;
  final String email;
  final String davinTechEmail;
  final String? memo;
  final String ratio;

  BoardItem({
    required this.id,
    required this.consumerName,
    required this.facilityLocation,
    required this.representativeName,
    required this.phoneNumber,
    required this.incomingPrimaryVoltage,
    required this.incomingSecondaryVoltage,
    required this.incomingCapacity,
    required this.generationPrimaryVoltage,
    required this.generationSecondaryVoltage,
    required this.generationCapacity,
    required this.solarVoltage,
    required this.solarCapacity,
    required this.storageVoltage,
    required this.storageCapacity,
    required this.weight,
    required this.supervisorName,
    required this.inspectorName,
    required this.feeWithTax,
    required this.email,
    required this.davinTechEmail,
    required this.memo,
    required this.ratio,
  });

  factory BoardItem.fromJson(Map<String, dynamic> json) {
    return BoardItem(
      id: json['id'] as int,
      consumerName: json['consumer_name'] as String,
      facilityLocation: json['facility_location'] as String,
      representativeName: json['representative_name'] as String,
      phoneNumber: json['phone_number'] as String,
      incomingPrimaryVoltage: json['incoming_primary_voltage'] as String,
      incomingSecondaryVoltage: json['incoming_secondary_voltage'] as String,
      incomingCapacity: json['incoming_capacity'] as String,
      generationPrimaryVoltage: json['generation_primary_voltage'] as String,
      generationSecondaryVoltage:
          json['generation_secondary_voltage'] as String,
      generationCapacity: json['generation_capacity'] as String,
      solarVoltage: json['solar_voltage'] as String,
      solarCapacity: json['solar_capacity'] as String,
      storageVoltage: json['storage_voltage'] as String,
      storageCapacity: json['storage_capacity'] as String,
      weight: json['weight'] as String,
      supervisorName: json['supervisor_name'] as String,
      inspectorName: json['inspector_name'] as String,
      feeWithTax: json['fee_with_tax'] as String,
      email: json['email'] as String,
      davinTechEmail: json['davin_tech_email'] as String,
      memo: json['memo'] as String? ?? '',
      ratio: json['ratio'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'consumer_name': consumerName,
    'facility_location': facilityLocation,
    'representative_name': representativeName,
    'phone_number': phoneNumber,
    'incoming_primary_voltage': incomingPrimaryVoltage,
    'incoming_secondary_voltage': incomingSecondaryVoltage,
    'incoming_capacity': incomingCapacity,
    'generation_primary_voltage': generationPrimaryVoltage,
    'generation_secondary_voltage': generationSecondaryVoltage,
    'generation_capacity': generationCapacity,
    'solar_voltage': solarVoltage,
    'solar_capacity': solarCapacity,
    'storage_voltage': storageVoltage,
    'storage_capacity': storageCapacity,
    'weight': weight,
    'supervisor_name': supervisorName,
    'inspector_name': inspectorName,
    'fee_with_tax': feeWithTax,
    'email': email,
    'davin_tech_email': davinTechEmail,
    'memo': memo,
    'ratio': ratio,
  };
}

extension BoardItemCopy on BoardItem {
  BoardItem copyWith({String? memo}) {
    return BoardItem(
      id: id,
      consumerName: consumerName,
      facilityLocation: facilityLocation,
      representativeName: representativeName,
      phoneNumber: phoneNumber,
      incomingPrimaryVoltage: incomingPrimaryVoltage,
      incomingSecondaryVoltage: incomingSecondaryVoltage,
      incomingCapacity: incomingCapacity,
      generationPrimaryVoltage: generationPrimaryVoltage,
      generationSecondaryVoltage: generationSecondaryVoltage,
      generationCapacity: generationCapacity,
      solarVoltage: solarVoltage,
      solarCapacity: solarCapacity,
      storageVoltage: storageVoltage,
      storageCapacity: storageCapacity,
      weight: weight,
      supervisorName: supervisorName,
      inspectorName: inspectorName,
      feeWithTax: feeWithTax,
      email: email,
      davinTechEmail: davinTechEmail,
      memo: memo ?? this.memo,
      ratio: ratio,
    );
  }
}
