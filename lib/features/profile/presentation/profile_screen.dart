import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/storage.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String name = 'Zapshop User';
  String phone = '';
  String city = 'Минск';
  bool pushEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final box = LocalStorage.getBox(LocalStorage.profileBox);
    setState(() {
      name = '${box.get('name') ?? 'Zapshop User'}';
      phone = '${box.get('phone') ?? ''}';
      city = '${box.get('city') ?? 'Минск'}';
      pushEnabled = box.get('pushEnabled') == null ? true : box.get('pushEnabled') == true;
    });
  }

  Future<void> _saveProfile() async {
    final box = LocalStorage.getBox(LocalStorage.profileBox);
    await box.put('name', name);
    await box.put('phone', phone);
    await box.put('city', city);
    await box.put('pushEnabled', pushEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(localRepoProvider);
    final favorites = repo.getFavorites();
    final cart = repo.getCart();
    final orders = repo.getOrders();

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const CircleAvatar(radius: 28, child: Icon(Icons.person)),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              subtitle: Text('${city.isEmpty ? 'Город не указан' : city}${phone.isEmpty ? '' : ' • $phone'}', style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(onPressed: _openEditProfile, icon: const Icon(Icons.edit, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metric(context, 'Избранное', '${favorites.length}', Icons.favorite_outline, '/favorites')),
              Expanded(child: _metric(context, 'Корзина', '${cart.length}', Icons.shopping_cart_outlined, '/cart')),
              Expanded(child: _metric(context, 'Заказы', '${orders.length}', Icons.receipt_long_outlined, '/orders')),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: pushEnabled,
                  onChanged: (v) async {
                    setState(() => pushEnabled = v);
                    await _saveProfile();
                  },
                  title: const Text('Push-уведомления'),
                  subtitle: const Text('Напоминания о ТО и статусах заказа'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('История заказов'),
                  onTap: () => context.push('/orders'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: const Text('Очистить локальные данные'),
                  subtitle: const Text('Cars, service, favorites, cart, requests, profile'),
                  onTap: () async {
                    for (final box in [LocalStorage.carsBox, LocalStorage.serviceBox, LocalStorage.favoritesBox, LocalStorage.cartBox, LocalStorage.requestsBox, LocalStorage.profileBox, LocalStorage.ordersBox]) {
                      await LocalStorage.getBox(box).clear();
                    }
                    if (!mounted) return;
                    _loadProfile();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Локальные данные очищены')));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String title, String value, IconData icon, String route) => InkWell(
        onTap: () => context.push(route),
        child: Card(
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
        ),
      );

  Future<void> _openEditProfile() async {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);
    final cityCtrl = TextEditingController(text: city);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Редактировать профиль'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Имя')),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон')),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Город')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                name = nameCtrl.text.trim().isEmpty ? 'Zapshop User' : nameCtrl.text.trim();
                phone = phoneCtrl.text.trim();
                city = cityCtrl.text.trim();
              });
              await _saveProfile();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
