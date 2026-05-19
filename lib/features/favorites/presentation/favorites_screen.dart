import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.read(localRepoProvider).getFavorites();
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: items.isEmpty
          ? const Center(child: Text('Избранное пусто'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final p = items[i];
                return Card(
                  child: ListTile(
                    leading: SizedBox(width: 60, height: 60, child: p.mainImage == null ? const Icon(Icons.image_not_supported) : CachedNetworkImage(imageUrl: p.mainImage!)),
                    title: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${p.price ?? 'Цена по запросу'} ${p.currency ?? ''}'),
                  ),
                );
              },
            ),
    );
  }
}
