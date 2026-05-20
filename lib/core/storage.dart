import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';

class LocalStorage {
  static const carsBox = 'cars';
  static const serviceBox = 'service_records';
  static const favoritesBox = 'favorites';
  static const cartBox = 'cart';
  static const requestsBox = 'requests';
  static const profileBox = 'profile';
  static const ordersBox = 'orders';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(carsBox),
      Hive.openBox(serviceBox),
      Hive.openBox(favoritesBox),
      Hive.openBox(cartBox),
      Hive.openBox(requestsBox),
      Hive.openBox(profileBox),
      Hive.openBox(ordersBox),
    ]);
  }

  static Box getBox(String name) => Hive.box(name);
}

class LocalRepo {
  static const recentPartsKey = 'recent_parts';
  List<Car> getCars() => LocalStorage.getBox(LocalStorage.carsBox).values.map((e) => Car.fromJson(Map<dynamic, dynamic>.from(e as Map))).toList();
  Future<void> saveCar(Car car) => LocalStorage.getBox(LocalStorage.carsBox).put(car.id, car.toJson());
  Future<void> deleteCar(String id) => LocalStorage.getBox(LocalStorage.carsBox).delete(id);

  List<ServiceRecord> getServices() => LocalStorage.getBox(LocalStorage.serviceBox).values.map((e) => ServiceRecord.fromJson(Map<dynamic, dynamic>.from(e as Map))).toList();
  Future<void> saveService(ServiceRecord r) => LocalStorage.getBox(LocalStorage.serviceBox).put(r.id, r.toJson());

  List<Part> getFavorites() => LocalStorage.getBox(LocalStorage.favoritesBox).values.map((e) => Part.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  Future<bool> addFavoriteIfAbsent(Part p) async {
    final b = LocalStorage.getBox(LocalStorage.favoritesBox);
    if (b.containsKey(p.id)) return false;
    await b.put(p.id, p.toJson());
    return true;
  }

  Future<void> removeFavorite(Part p) => LocalStorage.getBox(LocalStorage.favoritesBox).delete(p.id);

  List<Map<String, dynamic>> getCart() => LocalStorage.getBox(LocalStorage.cartBox).values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  Future<bool> addToCartIfAbsent(Part p) async {
    final b = LocalStorage.getBox(LocalStorage.cartBox);
    final ex = b.get(p.id);
    if (ex != null) return false;
    await b.put(p.id, {'part': p.toJson(), 'quantity': 1});
    return true;
  }

  Future<void> removeFromCart(int partId) => LocalStorage.getBox(LocalStorage.cartBox).delete(partId);

  List<AppRequest> getRequests() => LocalStorage.getBox(LocalStorage.requestsBox).values.map((e) => AppRequest.fromJson(Map<dynamic, dynamic>.from(e as Map))).toList();
  Future<void> saveRequest(AppRequest r) => LocalStorage.getBox(LocalStorage.requestsBox).put(r.id, r.toJson());

  List<OrderHistoryItem> getOrders() => LocalStorage.getBox(LocalStorage.ordersBox).values.map((e) => OrderHistoryItem.fromJson(Map<dynamic, dynamic>.from(e as Map))).toList();
  Future<void> saveOrder(OrderHistoryItem o) => LocalStorage.getBox(LocalStorage.ordersBox).put(o.id, o.toJson());
  Future<void> clearCart() => LocalStorage.getBox(LocalStorage.cartBox).clear();

  List<Part> getRecentParts() {
    final raw = LocalStorage.getBox(LocalStorage.profileBox).get(recentPartsKey);
    if (raw is! String || raw.isEmpty) return [];
    return Part.decodeList(raw);
  }

  Future<void> saveRecentPart(Part p) async {
    final list = getRecentParts();
    list.removeWhere((x) => x.id == p.id);
    list.insert(0, p);
    final cut = list.take(10).toList();
    await LocalStorage.getBox(LocalStorage.profileBox).put(recentPartsKey, Part.encodeList(cut));
  }
}

