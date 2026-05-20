import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models.dart';
import '../../../core/providers.dart';

final carsProvider = StateProvider<List<Car>>(
  (ref) => ref.read(localRepoProvider).getCars(),
);

final activeCarProvider = StateProvider<String?>((ref) => null);

final servicesProvider = StateProvider<List<ServiceRecord>>(
  (ref) => ref.read(localRepoProvider).getServices(),
);

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    final activeId = ref.watch(activeCarProvider);
    final services = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Гараж'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upsertCar(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Добавить авто'),
      ),
      body: cars.isEmpty
          ? const Center(
              child: Text('Добавьте автомобиль'),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: cars.map((car) {
                final carServices = services
                    .where((service) => service.carId == car.id)
                    .toList();

                final spent = carServices.fold<double>(
                  0,
                  (sum, service) => sum + service.price,
                );

                return Card(
                  child: ExpansionTile(
                    leading: Icon(
                      activeId == car.id
                          ? Icons.check_circle
                          : Icons.directions_car,
                    ),
                    title: Text(
                      car.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'VIN: ${car.vin.isEmpty ? '-' : car.vin} • ${car.mileage} км • ${car.status}',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _smallInfo(
                              'Обслуживаний',
                              '${carServices.length}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _smallInfo(
                              'Расходы',
                              '${spent.toStringAsFixed(2)} USD',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: () {
                              ref.read(activeCarProvider.notifier).state =
                                  car.id;
                            },
                            child: const Text('Сделать активным'),
                          ),
                          OutlinedButton(
                            onPressed: () => _upsertCar(
                              context,
                              ref,
                              car: car,
                            ),
                            child: const Text('Редактировать'),
                          ),
                          OutlinedButton(
                            onPressed: () => _addService(context, ref, car),
                            child: const Text('Добавить ремонт'),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              await ref
                                  .read(localRepoProvider)
                                  .deleteCar(car.id);

                              ref.read(carsProvider.notifier).state =
                                  ref.read(localRepoProvider).getCars();
                            },
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _smallInfo(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _upsertCar(
    BuildContext context,
    WidgetRef ref, {
    Car? car,
  }) {
    final vin = TextEditingController(text: car?.vin ?? '');
    final brand = TextEditingController(text: car?.brand ?? '');
    final model = TextEditingController(text: car?.model ?? '');
    final generation = TextEditingController(text: car?.generation ?? '');
    final year = TextEditingController(text: car?.year ?? '');
    final mileage = TextEditingController(text: '${car?.mileage ?? 0}');

    String photoPath = car?.photoPath ?? '';
    final picker = ImagePicker();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                car == null ? 'Добавить авто' : 'Редактировать авто',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: vin,
                            decoration: const InputDecoration(
                              labelText: 'VIN',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Декодировать VIN',
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () async {
                            final result = await _decodeVin(vin.text);

                            if (!dialogContext.mounted) return;

                            if (result == null) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'VIN не удалось декодировать',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (!result.ok) {
                              final msg = result.suggestedVin != null
                                  ? 'VIN содержит ошибку. Попробуйте: ${result.suggestedVin}'
                                  : result.errorText ??
                                      'VIN невалиден. Проверьте длину и символы.';

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                              return;
                            }

                            brand.text = result.make ?? brand.text;
                            model.text = result.model ?? model.text;
                            year.text = result.year ?? year.text;

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'VIN декодирован: ${result.make ?? '-'} ${result.model ?? '-'} ${result.year ?? '-'}',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: brand,
                      decoration: const InputDecoration(
                        labelText: 'Марка',
                      ),
                    ),
                    TextField(
                      controller: model,
                      decoration: const InputDecoration(
                        labelText: 'Модель',
                      ),
                    ),
                    TextField(
                      controller: generation,
                      decoration: const InputDecoration(
                        labelText: 'Поколение',
                      ),
                    ),
                    TextField(
                      controller: year,
                      decoration: const InputDecoration(
                        labelText: 'Год',
                      ),
                    ),
                    TextField(
                      controller: mileage,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Пробег',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final pickedImage = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );

                            if (pickedImage != null) {
                              setDialogState(() {
                                photoPath = pickedImage.path;
                              });
                            }
                          },
                          icon: const Icon(Icons.photo),
                          label: const Text('Фото авто'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            photoPath.isEmpty
                                ? 'Фото не выбрано'
                                : 'Фото выбрано',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final vinDecoded = await _decodeVin(vin.text);
                    final decoded = vinDecoded?.ok == true ? vinDecoded : null;

                    final item = Car(
                      id: car?.id ??
                          'car_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
                      vin: vin.text.trim(),
                      brand: brand.text.trim(),
                      model: model.text.trim(),
                      generation: generation.text.trim(),
                      year: year.text.trim(),
                      engine: decoded?.engineDisplay ?? car?.engine ?? '',
                      engineCode: car?.engineCode ?? '',
                      transmission: decoded?.transmissionDisplay ?? car?.transmission ?? '',
                      drive: car?.drive ?? '',
                      fuel: decoded?.fuelDisplay ?? car?.fuel ?? '',
                      mileage: int.tryParse(mileage.text.trim()) ?? 0,
                      country: decoded?.plantDisplay ?? car?.country ?? '',
                      isUsaImport: car?.isUsaImport ?? false,
                      status: car?.status ?? 'на ходу',
                      comment: decoded?.prettySummary ?? car?.comment ?? '',
                      photoPath: photoPath,
                    );

                    await ref.read(localRepoProvider).saveCar(item);

                    ref.read(carsProvider.notifier).state =
                        ref.read(localRepoProvider).getCars();

                    if (!dialogContext.mounted) return;

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addService(
    BuildContext context,
    WidgetRef ref,
    Car car,
  ) {
    final title = TextEditingController();
    final mileage = TextEditingController(text: '${car.mileage}');
    final price = TextEditingController();
    final nextMileage = TextEditingController();
    final nextDays = TextEditingController();

    const serviceTypes = [
      'масло двигателя',
      'масло АКПП',
      'антифриз',
      'тормозная жидкость',
      'свечи',
      'фильтр салона',
      'колодки',
      'подвеска',
      'прочее',
    ];

    String selectedType = serviceTypes.first;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Добавить обслуживание'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Тип обслуживания',
                      ),
                      items: serviceTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                      ),
                    ),
                    TextField(
                      controller: mileage,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Пробег',
                      ),
                    ),
                    TextField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Цена',
                      ),
                    ),
                    TextField(
                      controller: nextMileage,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'След. замена (пробег)',
                      ),
                    ),
                    TextField(
                      controller: nextDays,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'След. замена (через дней)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nextDaysValue = int.tryParse(
                      nextDays.text.trim(),
                    );

                    final service = ServiceRecord(
                      id: 'srv_${DateTime.now().millisecondsSinceEpoch}',
                      carId: car.id,
                      type: selectedType,
                      title: title.text.trim(),
                      date: DateTime.now(),
                      mileage: int.tryParse(mileage.text.trim()) ?? 0,
                      price: double.tryParse(
                            price.text.trim().replaceAll(',', '.'),
                          ) ??
                          0,
                      currency: 'USD',
                      comment: '',
                      nextMileage: int.tryParse(nextMileage.text.trim()),
                      nextDate: nextDaysValue == null
                          ? null
                          : DateTime.now().add(
                              Duration(days: nextDaysValue),
                            ),
                    );

                    await ref.read(localRepoProvider).saveService(service);

                    ref.read(servicesProvider.notifier).state =
                        ref.read(localRepoProvider).getServices();

                    if (!dialogContext.mounted) return;

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_VinDecodedResult?> _decodeVin(String rawVin) async {
    final vin = _normalizeVin(rawVin);

    if (vin.length != 17) {
      return _VinDecodedResult(
        ok: false,
        errorText: 'VIN должен содержать 17 символов после очистки.',
      );
    }

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
          headers: const {'Accept': 'application/json'},
        ),
      );

      final response = await dio.get(
        'https://vpic.nhtsa.dot.gov/api/vehicles/decodevinvalues/$vin',
        queryParameters: const {'format': 'json'},
      );

      final raw = Map<String, dynamic>.from(response.data as Map);
      final results = (raw['Results'] as List?) ?? [];

      if (results.isEmpty) {
        return _VinDecodedResult(
          ok: false,
          errorText: 'Пустой ответ декодера.',
        );
      }

      final map = Map<String, dynamic>.from(results.first as Map);

      String? normalize(String key) {
        final value = map[key]?.toString().trim();

        if (value == null ||
            value.isEmpty ||
            value == '0' ||
            value == 'Not Applicable') {
          return null;
        }

        return value;
      }

      final errorCode = normalize('ErrorCode');
      final errorText = normalize('ErrorText');
      final suggestedVin = _normalizeVin(normalize('SuggestedVIN') ?? '');
      final make = normalize('Make');
      final model = normalize('Model');
      final year = normalize('ModelYear');
      final trim = normalize('Trim');
      final displacement = normalize('DisplacementL');
      final fuel = normalize('FuelTypePrimary');
      final engineModel = normalize('EngineModel');
      final turbo = normalize('Turbo');
      final bodyClass = normalize('BodyClass');
      final doors = normalize('Doors');
      final tStyle = normalize('TransmissionStyle');
      final tSpeeds = normalize('TransmissionSpeeds');
      final manufacturer = normalize('Manufacturer');
      final plantCity = normalize('PlantCity');
      final plantState = normalize('PlantState');
      final plantCountry = normalize('PlantCountry');
      final vehicleType = normalize('VehicleType');
      final seats = normalize('Seats');
      final headlight = normalize('LowerBeamHeadlampLightSource');
      final tpms = normalize('TPMS');
      final safety = [normalize('ABS'), normalize('ESC'), normalize('LaneKeepSystem'), normalize('BlindSpotMon'), normalize('RearCrossTrafficAlert'), normalize('ForwardCollisionWarning')].whereType<String>().where((x)=>x.toLowerCase()=='standard').toList();

      final ok = (errorCode == null || errorCode == '0') &&
          (make != null || model != null || year != null);

      final title = [make, model, year, trim].whereType<String>().where((e)=>e.isNotEmpty).join(' ');
      final engineDisplay = [displacement, fuel, engineModel, turbo == 'Yes' ? 'turbo' : null].whereType<String>().where((e)=>e.isNotEmpty).join(', ');
      final transmissionDisplay = [tStyle, tSpeeds == null ? null : '$tSpeeds передач'].whereType<String>().join(', ');
      final plantDisplay = [plantCity, plantState, plantCountry].whereType<String>().join(', ');
      final safetyText = safety.isEmpty ? null : 'Безопасность: ABS/ESC/Lane Keep/Blind Spot/Rear Cross Traffic/FCW — Standard';
      final prettySummary = [
        title.isEmpty ? null : title,
        engineDisplay.isEmpty ? null : 'Двигатель: $engineDisplay',
        bodyClass == null ? null : 'Кузов: $bodyClass${doors == null ? '' : ', $doors двери'}',
        transmissionDisplay.isEmpty ? null : 'Коробка: $transmissionDisplay',
        manufacturer == null ? null : 'Производитель: $manufacturer',
        plantDisplay.isEmpty ? null : 'Завод: $plantDisplay',
        vehicleType == null ? null : 'Тип авто: $vehicleType',
        seats == null ? null : 'Мест: $seats',
        headlight == null ? null : 'Фары: $headlight',
        tpms == null ? null : 'TPMS: $tpms',
        safetyText,
      ].whereType<String>().join('\n');

      return _VinDecodedResult(
        ok: ok,
        make: make,
        model: model,
        year: year,
        errorText: errorText,
        suggestedVin: suggestedVin.isEmpty ? null : suggestedVin,
        engineDisplay: engineDisplay.isEmpty ? null : engineDisplay,
        transmissionDisplay: transmissionDisplay.isEmpty ? null : transmissionDisplay,
        fuelDisplay: fuel,
        plantDisplay: plantDisplay.isEmpty ? null : plantDisplay,
        prettySummary: prettySummary.isEmpty ? null : prettySummary,
      );
    } on DioException catch (e) {
      final msg = switch (e.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          'Нет соединения с VIN API или сервер долго отвечает. Проверьте интернет/VPN и попробуйте снова.',
        DioExceptionType.badResponse =>
          'VIN API вернул ошибку HTTP ${e.response?.statusCode ?? '-'}',
        _ => 'Ошибка запроса VIN API: ${e.message}',
      };
      return _VinDecodedResult(
        ok: false,
        errorText: msg,
      );
    } catch (_) {
      return _VinDecodedResult(
        ok: false,
        errorText: 'Ошибка сети VIN декодера.',
      );
    }
  }

  String _normalizeVin(String vin) {
    final clean = vin.toUpperCase().replaceAll(
          RegExp(r'[^A-Z0-9]'),
          '',
        );

    return clean.replaceAll(
      RegExp(r'[IOQ]'),
      '',
    );
  }
}

class _VinDecodedResult {
  _VinDecodedResult({required this.ok, this.make, this.model, this.year, this.errorText, this.suggestedVin, this.engineDisplay, this.transmissionDisplay, this.fuelDisplay, this.plantDisplay, this.prettySummary});

  final bool ok;
  final String? make;
  final String? model;
  final String? year;
  final String? errorText;
  final String? suggestedVin;
  final String? engineDisplay;
  final String? transmissionDisplay;
  final String? fuelDisplay;
  final String? plantDisplay;
  final String? prettySummary;
}
