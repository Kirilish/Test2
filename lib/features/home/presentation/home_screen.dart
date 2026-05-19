import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:zapshop_garage/features/garage/presentation/garage_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    final active = ref.watch(activeCarProvider);
    final services = ref.watch(servicesProvider);
    if (cars.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zapshop Garage')),
        body: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.directions_car, size: 42),
                SizedBox(height: 8),
                Text(
                    'Добавьте автомобиль, чтобы видеть запчасти, напоминания и историю обслуживания'),
              ]),
            ),
          ),
        ),
      );
    }
    final car =
        cars.firstWhere((e) => e.id == active, orElse: () => cars.first);
    final list = services.where((e) => e.carId == car.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final total = list.fold<double>(0, (p, e) => p + e.price);
    final reminders = _buildReminders(car.mileage, list);
    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Column(
              children: [
                if (car.photoPath.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.file(
                        File(car.photoPath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                  title: Text(car.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Пробег: ${car.mileage} км • VIN: ${car.vin.isEmpty ? '-' : car.vin}'),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                  child: _metricCard(
                      'Расходы',
                      '${total.toStringAsFixed(2)} USD',
                      Icons.payments_outlined)),
              Expanded(
                  child: _metricCard('Обслуживаний', '${list.length}',
                      Icons.build_circle_outlined)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Напоминания по обслуживанию',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (reminders.isEmpty)
            const Card(child: ListTile(title: Text('Нет активных напоминаний')))
          else
            ...reminders.map(
              (r) => Card(
                color: r.overdue ? Colors.red.withOpacity(0.2) : null,
                child: ListTile(
                  leading: Icon(r.overdue
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_active_outlined),
                  title: Text(r.title),
                  subtitle: Text(r.subtitle),
                  trailing: Text(r.overdue ? 'Просрочено' : 'Скоро'),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text('Последние работы',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...list.take(5).map((e) => Card(
                child: ListTile(
                  title: Text(e.title),
                  subtitle: Text(
                      '${DateFormat('dd.MM.yyyy').format(e.date)} • ${e.mileage} км'),
                  trailing: Text('${e.price.toStringAsFixed(0)} ${e.currency}'),
                ),
              )),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700))
                ]))
          ]),
        ),
      );

  List<_ReminderItem> _buildReminders(int currentMileage, List<dynamic> list) {
    final now = DateTime.now();
    return list
        .where((s) => s.nextMileage != null || s.nextDate != null)
        .map((s) {
      final byMileage = s.nextMileage != null
          ? (s.nextMileage as int) - currentMileage
          : null;
      final byDate = s.nextDate != null
          ? (s.nextDate as DateTime).difference(now).inDays
          : null;
      final overdue = (byMileage != null && byMileage <= 0) ||
          (byDate != null && byDate <= 0);
      final parts = <String>[];
      if (byMileage != null)
        parts.add(byMileage <= 0
            ? 'по пробегу: просрочено'
            : 'осталось $byMileage км');
      if (byDate != null)
        parts.add(byDate <= 0 ? 'по дате: просрочено' : 'осталось $byDate дн');
      return _ReminderItem(
          title: s.title, subtitle: parts.join(' • '), overdue: overdue);
    }).toList();
  }
}

class _ReminderItem {
  _ReminderItem(
      {required this.title, required this.subtitle, required this.overdue});
  final String title;
  final String subtitle;
  final bool overdue;
}
