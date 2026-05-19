import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(localRepoProvider);
    final favorites = repo.getFavorites();
    final cart = repo.getCart();
    final requests = repo.getRequests();

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        children: [
          const ListTile(title: Text('Имя'), subtitle: Text('User')),
          ListTile(title: const Text('Избранное'), subtitle: Text('${favorites.length} позиций')),
          ListTile(title: const Text('Корзина'), subtitle: Text('${cart.length} позиций')),
          ListTile(title: const Text('Мои заявки'), subtitle: Text('${requests.length}')),
          ListTile(
            title: const Text('Очистить локальные данные'),
            onTap: () async {
              for (final box in [LocalStorage.carsBox, LocalStorage.serviceBox, LocalStorage.favoritesBox, LocalStorage.cartBox, LocalStorage.requestsBox, LocalStorage.profileBox]) {
                await LocalStorage.getBox(box).clear();
              }
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Локальные данные очищены')));
            },
          ),
          const ListTile(title: Text('Версия'), subtitle: Text('1.0.0+1')),
        ],
      ),
    );
  }
}
