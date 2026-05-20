import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(localRepoProvider);
    final items = repo.getFavorites();
    final filtered = items.where((p) {
      final q = query.toLowerCase();
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q) || p.model.toLowerCase().contains(q) || p.partName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Поиск по избранному'),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Избранное пусто'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return Card(
                        child: ListTile(
                          leading: SizedBox(
                            width: 60,
                            height: 60,
                            child: p.mainImage == null ? const Icon(Icons.image_not_supported) : CachedNetworkImage(imageUrl: p.mainImage!),
                          ),
                          title: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${p.price ?? 'Цена по запросу'} ${p.currency ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await repo.removeFavorite(p);
                              if (mounted) setState(() {});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Удалено из избранного')));
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
