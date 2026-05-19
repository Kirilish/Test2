import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/storage.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Гараж')),
      floatingActionButton: FloatingActionButton(onPressed: () => _upsertCar(context, ref), child: const Icon(Icons.add)),
      body: cars.isEmpty
          ? const Center(child: Text('Добавьте автомобиль'))
          : ListView(
              children: cars
                  .map((c) => Card(
                        child: ListTile(
                          title: Text(c.title),
                          subtitle: Text('VIN: ${c.vin} • Пробег: ${c.mileage} км • ${c.status}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'active') ref.read(activeCarProvider.notifier).state = c.id;
                              if (v == 'edit') _upsertCar(context, ref, car: c);
                              if (v == 'delete') {
                                await ref.read(localRepoProvider).deleteCar(c.id);
                                ref.read(carsProvider.notifier).state = ref.read(localRepoProvider).getCars();
                              }
                              if (v == 'service') _addService(context, ref, c);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'active', child: Text('Сделать активным')),
                              PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                              PopupMenuItem(value: 'service', child: Text('Добавить ремонт')),
                              PopupMenuItem(value: 'delete', child: Text('Удалить')),
                            ],
                          ),
                          leading: Icon(activeId == c.id ? Icons.check_circle : Icons.directions_car),
                        ),
                      ))
                  .toList(),
            ),
    );
  }

  void _upsertCar(BuildContext context, WidgetRef ref, {Car? car}) {
    final vin = TextEditingController(text: car?.vin ?? '');
    final brand = TextEditingController(text: car?.brand ?? '');
    final model = TextEditingController(text: car?.model ?? '');
    final generation = TextEditingController(text: car?.generation ?? '');
    final year = TextEditingController(text: car?.year ?? '');
    final mileage = TextEditingController(text: '${car?.mileage ?? 0}');
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(car == null ? 'Добавить авто' : 'Редактировать авто'),
              content: SingleChildScrollView(
                child: Column(children: [
                  TextField(controller: vin, decoration: const InputDecoration(labelText: 'VIN')),
                  TextField(controller: brand, decoration: const InputDecoration(labelText: 'Марка')),
                  TextField(controller: model, decoration: const InputDecoration(labelText: 'Модель')),
                  TextField(controller: generation, decoration: const InputDecoration(labelText: 'Поколение')),
                  TextField(controller: year, decoration: const InputDecoration(labelText: 'Год')),
                  TextField(controller: mileage, decoration: const InputDecoration(labelText: 'Пробег')),
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                ElevatedButton(
                    onPressed: () async {
                      final c = Car(
                        id: car?.id ?? 'car_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
                        vin: vin.text,
                        brand: brand.text,
                        model: model.text,
                        generation: generation.text,
                        year: year.text,
                        engine: '',
                        engineCode: '',
                        transmission: '',
                        drive: '',
                        fuel: '',
                        mileage: int.tryParse(mileage.text) ?? 0,
                        country: '',
                        isUsaImport: false,
                        status: 'на ходу',
                        comment: '',
                      );
                      await ref.read(localRepoProvider).saveCar(c);
                      ref.read(carsProvider.notifier).state = ref.read(localRepoProvider).getCars();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Сохранить')),
              ],
            ));
  }

  void _addService(BuildContext context, WidgetRef ref, Car c) {
    final title = TextEditingController();
    final mileage = TextEditingController(text: '${c.mileage}');
    final price = TextEditingController();
    final nextMileage = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
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
                          nextMileage: int.tryParse(nextMileage.text)));
                      ref.read(servicesProvider.notifier).state = ref.read(localRepoProvider).getServices();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Сохранить'))
              ],
            ));
  }
}
