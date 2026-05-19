import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/storage.dart';
import '../../../core/providers.dart';
import '../data/zapshop_api_client.dart';

final apiProvider = Provider((ref) => ZapshopApiClient());

class MarketState {
  const MarketState({this.items = const [], this.page = 1, this.loading = false, this.hasMore = true, this.error});
  final List<Part> items;
  final int page;
  final bool loading;
  final bool hasMore;
  final String? error;
  MarketState copyWith({List<Part>? items, int? page, bool? loading, bool? hasMore, String? error}) =>
      MarketState(items: items ?? this.items, page: page ?? this.page, loading: loading ?? this.loading, hasMore: hasMore ?? this.hasMore, error: error);
}

class MarketNotifier extends StateNotifier<MarketState> {
  MarketNotifier(this._api) : super(const MarketState());
  final ZapshopApiClient _api;
  String _search = '';

  Future<void> refresh({String search = ''}) async {
    _search = search;
    state = state.copyWith(loading: true, page: 1, items: [], hasMore: true, error: null);
    await loadMore();
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _api.getParts(page: state.page, perPage: 20, search: _search);
      state = state.copyWith(items: [...state.items, ...data], page: state.page + 1, hasMore: data.length == 20, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Маркет Zapshop')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(controller: c, decoration: const InputDecoration(hintText: 'Поиск детали'))),
            IconButton(onPressed: () => ref.read(marketProvider.notifier).refresh(search: c.text), icon: const Icon(Icons.search)),
          ]),
        ),
        if (st.error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [Expanded(child: Text('Ошибка сети: ${st.error}', maxLines: 2)), TextButton(onPressed: () => ref.read(marketProvider.notifier).refresh(search: c.text), child: const Text('Retry'))])),
        Expanded(
          child: st.items.isEmpty && st.loading
              ? const Center(child: CircularProgressIndicator())
              : st.items.isEmpty
                  ? const Center(child: Text('Список пуст'))
                  : ListView.builder(
                      controller: scroll,
                      itemCount: st.items.length + (st.loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= st.items.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        final p = st.items[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: p.mainImage == null || p.mainImage!.isEmpty ? const Icon(Icons.image_not_supported) : CachedNetworkImage(imageUrl: p.mainImage!, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.title, maxLines: 2), Text('${p.brand} ${p.model} ${p.generation}'), Text(p.price == null ? 'Цена по запросу' : '${p.price} ${p.currency ?? ''}')]))
                              ]),
                              Wrap(spacing: 6, children: [
                                OutlinedButton(onPressed: () => _openDetail(context, p), child: const Text('Подробнее')),
                                OutlinedButton(onPressed: () => ref.read(localRepoProvider).toggleFavorite(p), child: const Text('В избранное')),
                                OutlinedButton(onPressed: () => ref.read(localRepoProvider).addToCart(p), child: const Text('В корзину')),
                                OutlinedButton(onPressed: () => _askAi(context, p), child: const Text('Спросить AI')),
                              ])
                            ]),
                          ),
                        );
                      }),
        )
      ]),
    );
  }

  void _askAi(BuildContext context, Part p) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI: по "${p.partName}" сверяйте VIN/OEM перед покупкой.')));
  }

  Future<void> _openDetail(BuildContext context, Part p) async {
    final api = ref.read(apiProvider);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => FutureBuilder<Part>(
            future: api.getPartDetails(p.id),
            builder: (_, s) {
              if (s.connectionState != ConnectionState.done) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
              if (s.hasError || s.data == null) return const SizedBox(height: 300, child: Center(child: Text('Ошибка загрузки карточки')));
              final d = s.data!;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Совместимость не подтверждена. Отправьте VIN/OEM для проверки.'),
                  const SizedBox(height: 8),
                  Text(d.price == null ? 'Цена по запросу' : '${d.price} ${d.currency ?? ''}'),
                  Text('Адрес: ${d.address ?? '-'}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: () async {
                        final ok = await _sendRequest(d);
                        if (mounted) Navigator.pop(context);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Заявка отправлена' : 'Ошибка отправки заявки')));
                      },
                      child: const Text('Оформить заявку')),
                ]),
              );
            }));
  }

  Future<bool> _sendRequest(Part p) async {
    try {
      final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      await ref.read(apiProvider).createRequest({'name': 'Mobile User', 'phone': '+000000', 'brand': p.brand, 'model': p.model, 'part_name': p.partName, 'comment': 'Заказ из корзины', 'source': 'mobile_app'});
      await ref.read(localRepoProvider).saveRequest(AppRequest(id: requestId, requestId: null, name: 'Mobile User', phone: '+000000', partName: p.partName, brand: p.brand, model: p.model, createdAt: DateTime.now(), status: 'отправлена'));
      return true;
    } catch (_) {
      return false;
    }
  }
}
