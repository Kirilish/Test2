import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/providers.dart';

final carsProvider = StateProvider<List<Car>>((ref) => ref.read(localRepoProvider).getCars());
final activeCarProvider = StateProvider<String?>((ref) => null);
final servicesProvider = StateProvider<List<ServiceRecord>>((ref) => ref.read(localRepoProvider).getServices());

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    final activeId = ref.watch(activeCarProvider);
    final services = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Гараж')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _upsertCar(context, ref), icon: const Icon(Icons.add), label: const Text('Добавить авто')),
      body: cars.isEmpty
          ? const Center(child: Text('Добавьте автомобиль'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: cars.map((c) {
                final carServices = services.where((e) => e.carId == c.id).toList();
                final spent = carServices.fold<double>(0, (p, e) => p + e.price);
                return Card(
                  child: ExpansionTile(
                    leading: Icon(activeId == c.id ? Icons.check_circle : Icons.directions_car),
                    title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('VIN: ${c.vin.isEmpty ? '-' : c.vin} • ${c.mileage} км • ${c.status}'),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      Row(children: [
                        Expanded(child: _smallInfo('Обслуживаний', '${carServices.length}')),
                        const SizedBox(width: 8),
                        Expanded(child: _smallInfo('Расходы', '${spent.toStringAsFixed(2)} USD')),
                      ]),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        FilledButton.tonal(onPressed: () => ref.read(activeCarProvider.notifier).state = c.id, child: const Text('Сделать активным')),
                        OutlinedButton(onPressed: () => _upsertCar(context, ref, car: c), child: const Text('Редактировать')),
                        OutlinedButton(onPressed: () => _addService(context, ref, c), child: const Text('Добавить ремонт')),
                        OutlinedButton(
                          onPressed: () async {
                            await ref.read(localRepoProvider).deleteCar(c.id);
                            ref.read(carsProvider.notifier).state = ref.read(localRepoProvider).getCars();
                          },
                          child: const Text('Удалить'),
                        ),
                      ]),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _smallInfo(String t, String v) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 12)), const SizedBox(height: 4), Text(v, style: const TextStyle(fontWeight: FontWeight.w700))]),
      );

  void _upsertCar(BuildContext context, WidgetRef ref, {Car? car}) {
    final vin = TextEditingController(text: car?.vin ?? '');
    final brand = TextEditingController(text: car?.brand ?? '');
    final model = TextEditingController(text: car?.model ?? '');
    final generation = TextEditingController(text: car?.generation ?? '');
    final year = TextEditingController(text: car?.year ?? '');
    final mileage = TextEditingController(text: '${car?.mileage ?? 0}');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(car == null ? 'Добавить авто' : 'Редактировать авто'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: vin, decoration: const InputDecoration(labelText: 'VIN')),
              TextField(controller: brand, decoration: const InputDecoration(labelText: 'Марка')),
              TextField(controller: model, decoration: const InputDecoration(labelText: 'Модель')),
              TextField(controller: generation, decoration: const InputDecoration(labelText: 'Поколение')),
              TextField(controller: year, decoration: const InputDecoration(labelText: 'Год')),
              TextField(controller: mileage, decoration: const InputDecoration(labelText: 'Пробег')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final item = Car(
                id: car?.id ?? 'car_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
                vin: vin.text.trim(),
                brand: brand.text.trim(),
                model: model.text.trim(),
                generation: generation.text.trim(),
                year: year.text.trim(),
                engine: car?.engine ?? '',
                engineCode: car?.engineCode ?? '',
                transmission: car?.transmission ?? '',
                drive: car?.drive ?? '',
                fuel: car?.fuel ?? '',
                mileage: int.tryParse(mileage.text.trim()) ?? 0,
                country: car?.country ?? '',
                isUsaImport: car?.isUsaImport ?? false,
                status: car?.status ?? 'на ходу',
                comment: car?.comment ?? '',
              );
              await ref.read(localRepoProvider).saveCar(item);
              ref.read(carsProvider.notifier).state = ref.read(localRepoProvider).getCars();
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _addService(BuildContext context, WidgetRef ref, Car c) {
    final title = TextEditingController();
    final mileage = TextEditingController(text: '${c.mileage}');
    final price = TextEditingController();
    final nextMileage = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Добавить обслуживание'),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: mileage, decoration: const InputDecoration(labelText: 'Пробег')),
            TextField(controller: price, decoration: const InputDecoration(labelText: 'Цена')),
            TextField(controller: nextMileage, decoration: const InputDecoration(labelText: 'След. замена (пробег)')),
          ]),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await ref.read(localRepoProvider).saveService(ServiceRecord(
                    id: 'srv_${DateTime.now().millisecondsSinceEpoch}',
                    carId: c.id,
                    type: 'прочее',
                    title: title.text,
                    date: DateTime.now(),
                    mileage: int.tryParse(mileage.text) ?? 0,
                    price: double.tryParse(price.text) ?? 0,
                    currency: 'USD',
                    comment: '',
                    nextMileage: int.tryParse(nextMileage.text),
                  ));
              ref.read(servicesProvider.notifier).state = ref.read(localRepoProvider).getServices();
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Сохранить'),
          )
        ],
      ),
    );
  }
}
