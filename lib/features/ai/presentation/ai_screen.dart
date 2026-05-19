import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/storage.dart';

abstract class AiService {
  Future<AiMessage> chat({required String message, File? image});
}

class AiMessage {
  AiMessage({required this.text, this.actions = const []});
  final String text;
  final List<String> actions;
}

class BackendAiProxyService implements AiService {
  BackendAiProxyService(this._dio);
  final Dio _dio;

  @override
  Future<AiMessage> chat({required String message, File? image}) async {
    final payload = {
      'message': message,
      if (image != null) 'image_base64': base64Encode(await image.readAsBytes()),
    };
    final response = await _dio.post('/api/ai/chat', data: payload);
    final data = Map<String, dynamic>.from(response.data as Map);
    return AiMessage(
      text: '${data['text'] ?? ''}',
      actions: (data['actions'] as List?)?.map((e) => '$e').toList() ?? const [],
    );
  }
}

class MockAiService implements AiService {
  @override
  Future<AiMessage> chat({required String message, File? image}) async {
    // TODO: Replace MockAiService with real backend AI proxy using OpenAI Responses API.
    final q = message.toLowerCase();
    final imageHint = image != null ? 'Фото получено. Похоже на запчасть, но нужна маркировка, VIN и OEM для точного вывода.' : '';
    return AiMessage(
      text:
          'Вопрос: $message\n$imageHint\nМогу помочь подобрать деталь и объяснить риски б/у. Без VIN/OEM нельзя подтвердить 100% совместимость. Для точного подбора сверяйте VIN, OEM, комплектацию и фото старой детали.',
      actions: q.contains('фара') || q.contains('бампер') ? const ['Открыть маркет', 'Оставить заявку'] : const ['Открыть маркет'],
    );
  }
}

class AiSettings {
  AiSettings({required this.useProxy, required this.proxyBaseUrl});
  final bool useProxy;
  final String proxyBaseUrl;

  Map<String, dynamic> toJson() => {'useProxy': useProxy, 'proxyBaseUrl': proxyBaseUrl};
  factory AiSettings.fromJson(Map<dynamic, dynamic> j) => AiSettings(useProxy: j['useProxy'] == true, proxyBaseUrl: '${j['proxyBaseUrl'] ?? 'http://10.0.2.2:8080'}');
}

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final c = TextEditingController();
  final imagePicker = ImagePicker();
  String answer = '';
  List<String> actions = const [];
  bool loading = false;
  File? attachedImage;
  AiSettings settings = AiSettings(useProxy: false, proxyBaseUrl: 'http://10.0.2.2:8080');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = LocalStorage.getBox(LocalStorage.profileBox);
    final raw = box.get('ai_settings');
    if (raw is Map) {
      setState(() => settings = AiSettings.fromJson(raw));
    }
  }

  Future<void> _saveSettings() async {
    await LocalStorage.getBox(LocalStorage.profileBox).put('ai_settings', settings.toJson());
  }

  AiService _service() {
    if (settings.useProxy) {
      return BackendAiProxyService(
        Dio(BaseOptions(
          baseUrl: settings.proxyBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
        )),
      );
    }
    return MockAiService();
  }

  @override
  Widget build(BuildContext context) {
    final chips = ['Что проверить перед покупкой двигателя?', 'Нужна фара', 'Нужен бампер', 'Что это за запчасть по фото?'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI-помощник'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Card(
            child: ListTile(
              title: Text(settings.useProxy ? 'Режим: Backend AI Proxy' : 'Режим: Mock AI'),
              subtitle: Text(settings.useProxy ? settings.proxyBaseUrl : 'Локальный безопасный mock без ключа'),
            ),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: chips.map((e) => ActionChip(label: Text(e), onPressed: () => setState(() => c.text = e))).toList()),
          const SizedBox(height: 8),
          TextField(controller: c, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'Ваш вопрос', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          Row(children: [
            OutlinedButton.icon(
              onPressed: () async {
                final x = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (x != null) setState(() => attachedImage = File(x.path));
              },
              icon: const Icon(Icons.photo),
              label: const Text('Фото'),
            ),
            const SizedBox(width: 8),
            if (attachedImage != null) const Text('Фото прикреплено')
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() => loading = true);
                  try {
                    final msg = await _service().chat(message: c.text, image: attachedImage);
                    setState(() {
                      answer = msg.text;
                      actions = msg.actions;
                    });
                  } catch (e) {
                    setState(() => answer = 'Ошибка AI: $e');
                  } finally {
                    setState(() => loading = false);
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Спросить'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (loading) const CircularProgressIndicator(),
          if (!loading && answer.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(answer),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: actions
                            .map((e) => OutlinedButton(
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Действие: $e'))),
                                  child: Text(e),
                                ))
                            .toList(),
                      )
                    ]),
                  ),
                ),
              ),
            )
        ]),
      ),
    );
  }

  Future<void> _openSettings() async {
    final urlCtrl = TextEditingController(text: settings.proxyBaseUrl);
    bool useProxy = settings.useProxy;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Настройки AI'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile.adaptive(
                value: useProxy,
                onChanged: (v) => setDialogState(() => useProxy = v),
                title: const Text('Использовать Backend Proxy'),
              ),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'Base URL Proxy', hintText: 'http://10.0.2.2:8080'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Отмена')),
            ElevatedButton(
            onPressed: () async {
              setState(() {
                settings = AiSettings(useProxy: useProxy, proxyBaseUrl: urlCtrl.text.trim().isEmpty ? 'http://10.0.2.2:8080' : urlCtrl.text.trim());
              });
              await _saveSettings();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Сохранить'),
            )
          ],
        ),
      ),
    );
  }
}
