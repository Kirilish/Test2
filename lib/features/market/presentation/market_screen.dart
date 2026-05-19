import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models.dart';
import '../../../core/providers.dart';
import '../../garage/presentation/garage_screen.dart';
import '../data/zapshop_api_client.dart';

final apiProvider = Provider((ref) => ZapshopApiClient());

class MarketState {
  const MarketState({this.items = const [], this.page = 1, this.loading = false, this.initialLoading = false, this.hasMore = true, this.error});
  final List<Part> items;
  final int page;
  final bool loading;
  final bool initialLoading;
  final bool hasMore;
  final String? error;
  MarketState copyWith({List<Part>? items, int? page, bool? loading, bool? initialLoading, bool? hasMore, String? error}) => MarketState(
        items: items ?? this.items,
        page: page ?? this.page,
        loading: loading ?? this.loading,
        initialLoading: initialLoading ?? this.initialLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

class MarketNotifier extends StateNotifier<MarketState> {
  MarketNotifier(this._api) : super(const MarketState());
  final ZapshopApiClient _api;
  String _search = '';

  Future<void> refresh({String search = ''}) async {
    _search = search;
    state = state.copyWith(initialLoading: true, loading: false, page: 1, items: [], hasMore: true, error: null);
    await _loadPage(reset: true);
  }

  Future<void> loadMore() => _loadPage(reset: false);

  Future<void> _loadPage({required bool reset}) async {
    if (state.loading || (!state.hasMore && !reset)) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final targetPage = reset ? 1 : state.page;
      final data = await _api.getParts(page: targetPage, perPage: 20, search: _search);
      state = state.copyWith(
        items: reset ? data : [...state.items, ...data],
        page: targetPage + 1,
        hasMore: data.length == 20,
        loading: false,
        initialLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(loading: false, initialLoading: false, error: '$e');
    }
  }

  Future<List<Part>> loadForCar(Car car) => _api.matchCar(brand: car.brand, model: car.model, generation: car.generation);
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) => MarketNotifier(ref.watch(apiProvider))..refresh());

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final c = TextEditingController();
  final scroll = ScrollController();
  bool onlyActiveCar = false;
  String selectedCategory = '';
  String sortMode = 'new';
  final categories = const ['Двигатель','Коробка','Фара','Бампер','Дверь','Капот','Крыло','Зеркало','Радиатор','Турбина'];

  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (scroll.position.pixels > scroll.position.maxScrollExtent - 400) {
        ref.read(marketProvider.notifier).loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(marketProvider);
    final cars = ref.watch(carsProvider);
    final activeId = ref.watch(activeCarProvider);
    final activeCar = cars.where((e) => e.id == activeId).cast<Car?>().firstOrNull ?? (cars.isNotEmpty ? cars.first : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Маркет Zapshop'), actions: [IconButton(onPressed: ()=>context.push('/favorites'), icon: const Icon(Icons.favorite_border)), IconButton(onPressed: ()=>context.push('/cart'), icon: const Icon(Icons.shopping_cart_outlined))]),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(controller: c, decoration: const InputDecoration(hintText: 'Поиск детали', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              IconButton(onPressed: () => ref.read(marketProvider.notifier).refresh(search: c.text), icon: const Icon(Icons.search)),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final label = i == 0 ? 'Все' : categories[i - 1];
                  final active = i == 0 ? selectedCategory.isEmpty : selectedCategory == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: active,
                    onSelected: (_) async {
                      setState(() => selectedCategory = i == 0 ? '' : label);
                      final q = [c.text.trim(), selectedCategory].where((e) => e.isNotEmpty).join(' ');
                      await ref.read(marketProvider.notifier).refresh(search: q);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              ChoiceChip(label: const Text('Новые'), selected: sortMode == 'new', onSelected: (_) async { setState(() => sortMode = 'new'); await ref.read(marketProvider.notifier).refresh(search: [c.text.trim(), selectedCategory].where((e) => e.isNotEmpty).join(' ')); }),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Дешевле'), selected: sortMode == 'cheap', onSelected: (_) async { setState(() => sortMode = 'cheap'); await ref.read(marketProvider.notifier).refresh(search: [c.text.trim(), selectedCategory].where((e) => e.isNotEmpty).join(' ')); }),
            ]),
            Row(children: [
              Expanded(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: onlyActiveCar,
                  title: const Text('Запчасти под мое авто'),
                  onChanged: (v) async {
                    setState(() => onlyActiveCar = v);
                    if (v && activeCar != null && activeCar.brand.isNotEmpty && activeCar.model.isNotEmpty) {
                      final data = await ref.read(marketProvider.notifier).loadForCar(activeCar);
                      ref.read(marketProvider.notifier).state = MarketState(items: data, page: 2, hasMore: false, loading: false, initialLoading: false);
                      if (context.mounted && data.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('По точному фильтру пусто. Показаны fallback результаты/поиск.')));
                      }
                    } else {
                      await ref.read(marketProvider.notifier).refresh(search: c.text);
                    }
                  },
                ),
              )
            ])
          ]),
        ),
        if (st.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              color: Colors.red.withOpacity(0.15),
              child: ListTile(
                title: const Text('Ошибка загрузки'),
                subtitle: Text(st.error!),
                trailing: TextButton(onPressed: () => ref.read(marketProvider.notifier).refresh(search: c.text), child: const Text('Retry')),
              ),
            ),
          ),
        Expanded(
          child: st.items.isEmpty && st.initialLoading
              ? const Center(child: CircularProgressIndicator())
              : st.items.isEmpty
                  ? const Center(child: Text('Запчасти не найдены'))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(marketProvider.notifier).refresh(search: [c.text.trim(), selectedCategory].where((e) => e.isNotEmpty).join(' ')),
                      child: ListView.builder(
                      controller: scroll,
                      itemCount: st.items.length + (st.loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= st.items.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        final sorted = [...st.items];
                        if (sortMode == 'cheap') {
                          sorted.sort((a,b) => (a.price ?? 1e12).compareTo(b.price ?? 1e12));
                        }
                        final p = sorted[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: p.mainImage == null || p.mainImage!.isEmpty
                                        ? Container(color: const Color(0xFF334155), child: const Icon(Icons.image_not_supported))
                                        : CachedNetworkImage(imageUrl: p.mainImage!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: const Color(0xFF334155), child: const Icon(Icons.broken_image))),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('${p.brand} ${p.model} ${p.generation}'),
                                    const SizedBox(height: 4),
                                    Text(p.price == null ? 'Цена по запросу' : '${p.price} ${p.currency ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ]),
                                )
                              ]),
                              const SizedBox(height: 8),
                              Wrap(spacing: 6, runSpacing: 6, children: [
                                FilledButton.tonal(onPressed: () => _openDetail(context, p), child: const Text('Подробнее')),
                                OutlinedButton(onPressed: () => ref.read(localRepoProvider).toggleFavorite(p), child: const Text('В избранное')),
                                OutlinedButton(onPressed: () => ref.read(localRepoProvider).addToCart(p), child: const Text('В корзину')),
                              ])
                            ]),
                          ),
                        );
                      },
                    ),
                    )
        )
      ]),
    );
  }

  Future<void> _openDetail(BuildContext context, Part p) async {
    final api = ref.read(apiProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) => FutureBuilder<Part>(
        future: api.getPartDetails(p.id),
        builder: (_, s) {
          if (s.connectionState != ConnectionState.done) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
          if (s.hasError || s.data == null) return const SizedBox(height: 300, child: Center(child: Text('Ошибка загрузки карточки')));
          final d = s.data!;
          final images = (d.images != null && d.images!.isNotEmpty) ? d.images! : (d.mainImage == null ? <String>[] : [d.mainImage!]);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (images.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: PageView(
                      children: images
                          .map((u) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(imageUrl: u, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: const Color(0xFF334155), child: const Icon(Icons.broken_image))),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(d.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Марка/модель: ${d.brand} ${d.model} ${d.generation}'),
                Text('Деталь: ${d.partName}'),
                const Text('Совместимость не подтверждена. Отправьте VIN/OEM для проверки.'),
                const SizedBox(height: 8),
                Text(d.price == null ? 'Цена по запросу' : '${d.price} ${d.currency ?? ''}'),
                Text('Адрес: ${d.address ?? '-'}'),
                if (d.oem != null && d.oem!.isNotEmpty) Text('OEM: ${d.oem}'),
                const SizedBox(height: 8),
                ElevatedButton(
                onPressed: () async {
                  final ok = await _sendRequest(d);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Заявка отправлена' : 'Ошибка отправки заявки')));
                },
                child: const Text('Оформить заявку'),
              ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _sendRequest(Part p) async {
    try {
      final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      await ref.read(apiProvider).createRequest({'name': 'Mobile User', 'phone': '+000000', 'brand': p.brand, 'model': p.model, 'part_name': p.partName, 'comment': 'Заказ из приложения', 'source': 'mobile_app'});
      await ref.read(localRepoProvider).saveRequest(AppRequest(id: requestId, requestId: null, name: 'Mobile User', phone: '+000000', partName: p.partName, brand: p.brand, model: p.model, createdAt: DateTime.now(), status: 'отправлена'));
      return true;
    } catch (_) {
      return false;
    }
  }
}

extension _IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
