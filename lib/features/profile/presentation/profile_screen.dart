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
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Zapshop User', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Город: Минск • Уведомления включены'),
              trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
            ),
          ),
          Row(
            children: [
              Expanded(child: _metric('Избранное', '${favorites.length}', Icons.favorite_outline)),
              Expanded(child: _metric('Корзина', '${cart.length}', Icons.shopping_cart_outlined)),
              Expanded(child: _metric('Заявки', '${requests.length}', Icons.assignment_outlined)),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(value: true, onChanged: (_) {}, title: const Text('Push-уведомления')),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_delete_outlined),
                  title: const Text('Очистить кэш изображений'),
                  subtitle: const Text('Освободить место на устройстве'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Кэш изображений очищен'))),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: const Text('Очистить локальные данные'),
                  subtitle: const Text('Cars, service, favorites, cart, requests, profile'),
                  onTap: () async {
                    for (final box in [LocalStorage.carsBox, LocalStorage.serviceBox, LocalStorage.favoritesBox, LocalStorage.cartBox, LocalStorage.requestsBox, LocalStorage.profileBox]) {
                      await LocalStorage.getBox(box).clear();
                    }
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Локальные данные очищены')));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Версия приложения'),
              subtitle: Text('1.0.0+1'),
            ),
          )
        ],
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Icon(icon, size: 18),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
