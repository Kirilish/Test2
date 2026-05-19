import 'dart:convert';

class Car {
  Car({
    required this.id,
    required this.vin,
    required this.brand,
    required this.model,
    required this.generation,
    required this.year,
    required this.engine,
    required this.engineCode,
    required this.transmission,
    required this.drive,
    required this.fuel,
    required this.mileage,
    required this.country,
    required this.isUsaImport,
    required this.status,
    required this.comment,
  });

  final String id;
  final String vin;
  final String brand;
  final String model;
  final String generation;
  final String year;
  final String engine;
  final String engineCode;
  final String transmission;
  final String drive;
  final String fuel;
  final int mileage;
  final String country;
  final bool isUsaImport;
  final String status;
  final String comment;

  String get title => '$brand $model $year'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'vin': vin,
        'brand': brand,
        'model': model,
        'generation': generation,
        'year': year,
        'engine': engine,
        'engineCode': engineCode,
        'transmission': transmission,
        'drive': drive,
        'fuel': fuel,
        'mileage': mileage,
        'country': country,
        'isUsaImport': isUsaImport,
        'status': status,
        'comment': comment,
      };

  factory Car.fromJson(Map<dynamic, dynamic> json) => Car(
        id: '${json['id'] ?? ''}',
        vin: '${json['vin'] ?? ''}',
        brand: '${json['brand'] ?? ''}',
        model: '${json['model'] ?? ''}',
        generation: '${json['generation'] ?? ''}',
        year: '${json['year'] ?? ''}',
        engine: '${json['engine'] ?? ''}',
        engineCode: '${json['engineCode'] ?? ''}',
        transmission: '${json['transmission'] ?? ''}',
        drive: '${json['drive'] ?? ''}',
        fuel: '${json['fuel'] ?? ''}',
        mileage: (json['mileage'] ?? 0) is int ? json['mileage'] as int : int.tryParse('${json['mileage']}') ?? 0,
        country: '${json['country'] ?? ''}',
        isUsaImport: json['isUsaImport'] == true,
        status: '${json['status'] ?? 'на ходу'}',
        comment: '${json['comment'] ?? ''}',
      );
}

class ServiceRecord {
  ServiceRecord({required this.id, required this.carId, required this.type, required this.title, required this.date, required this.mileage, required this.price, required this.currency, required this.comment, this.nextMileage, this.nextDate});
  final String id;
  final String carId;
  final String type;
  final String title;
  final DateTime date;
  final int mileage;
  final double price;
  final String currency;
  final String comment;
  final int? nextMileage;
  final DateTime? nextDate;

  Map<String, dynamic> toJson() => {'id': id, 'carId': carId, 'type': type, 'title': title, 'date': date.toIso8601String(), 'mileage': mileage, 'price': price, 'currency': currency, 'comment': comment, 'nextMileage': nextMileage, 'nextDate': nextDate?.toIso8601String()};
  factory ServiceRecord.fromJson(Map<dynamic, dynamic> json) => ServiceRecord(
      id: '${json['id']}',
      carId: '${json['carId']}',
      type: '${json['type'] ?? ''}',
      title: '${json['title'] ?? ''}',
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      mileage: int.tryParse('${json['mileage'] ?? 0}') ?? 0,
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      currency: '${json['currency'] ?? 'USD'}',
      comment: '${json['comment'] ?? ''}',
      nextMileage: json['nextMileage'] == null ? null : int.tryParse('${json['nextMileage']}'),
      nextDate: json['nextDate'] == null ? null : DateTime.tryParse('${json['nextDate']}'));
}

class Part {
  Part({required this.id, required this.title, required this.brand, required this.model, required this.generation, required this.partName, this.price, this.currency, this.address, this.mainImage, this.url, this.oem, this.images});
  final int id;
  final String title;
  final String brand;
  final String model;
  final String generation;
  final String partName;
  final num? price;
  final String? currency;
  final String? address;
  final String? mainImage;
  final String? url;
  final String? oem;
  final List<String>? images;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'brand': brand, 'model': model, 'generation': generation, 'part_name': partName, 'price': price, 'currency': currency, 'address': address, 'main_image': mainImage, 'url': url, 'oem': oem, 'images': images};

  factory Part.fromJson(Map<String, dynamic> j) => Part(
      id: (j['id'] ?? 0) as int,
      title: '${j['title'] ?? ''}',
      brand: '${j['brand'] ?? ''}',
      model: '${j['model'] ?? ''}',
      generation: '${j['generation'] ?? ''}',
      partName: '${j['part_name'] ?? ''}',
      price: j['price'] as num?,
      currency: j['currency']?.toString(),
      address: j['address']?.toString(),
      mainImage: j['main_image']?.toString(),
      url: j['url']?.toString(),
      oem: j['oem']?.toString(),
      images: (j['images'] as List?)?.map((e) => '$e').toList());

  static String encodeList(List<Part> list) => jsonEncode(list.map((e) => e.toJson()).toList());
  static List<Part> decodeList(String raw) => (jsonDecode(raw) as List).map((e) => Part.fromJson(Map<String, dynamic>.from(e))).toList();
}

class AppRequest {
  AppRequest({required this.id, required this.name, required this.phone, required this.partName, required this.brand, required this.model, required this.createdAt, required this.status, this.requestId});
  final String id;
  final String? requestId;
  final String name;
  final String phone;
  final String partName;
  final String brand;
  final String model;
  final DateTime createdAt;
  final String status;
  Map<String, dynamic> toJson() => {'id': id, 'requestId': requestId, 'name': name, 'phone': phone, 'partName': partName, 'brand': brand, 'model': model, 'createdAt': createdAt.toIso8601String(), 'status': status};
  factory AppRequest.fromJson(Map<dynamic, dynamic> j) => AppRequest(id: '${j['id']}', requestId: j['requestId']?.toString(), name: '${j['name']}', phone: '${j['phone']}', partName: '${j['partName']}', brand: '${j['brand']}', model: '${j['model']}', createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(), status: '${j['status'] ?? 'отправлена'}');
}
