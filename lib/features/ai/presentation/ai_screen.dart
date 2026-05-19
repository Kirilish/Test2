import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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
    final hasPartKeywords = q.contains('фара') || q.contains('бампер') || q.contains('двигатель') || q.contains('коробка') || q.contains('что это за запчасть');
    final imageHint = image != null ? 'Фото получено. По фото можно сделать предварительную оценку, но нужно сверить VIN/OEM и маркировки на детали.' : '';
    if (hasPartKeywords) {
      return AiMessage(
        text:
            'Уточните VIN/OEM, сторону детали и комплектацию. $imageHint Не обещаю 100% совместимость без проверки. Для точного подбора нужно сверить VIN, OEM, комплектацию и фото старой детали.',
        actions: const ['Открыть маркет', 'Оставить заявку'],
      );
    }
    return AiMessage(
      text: 'Могу помочь с подбором запчастей, рисками б/у деталей и чек-листом проверки. $imageHint Для точного подбора нужно сверить VIN, OEM, комплектацию и фото старой детали.',
      actions: const ['Открыть маркет'],
    );
  }
}

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final service = MockAiService();
  final c = TextEditingController();
  String answer = '';
  List<String> actions = const [];
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final chips = ['Что проверить перед покупкой двигателя?', 'Нужна фара', 'Нужен бампер', 'Что значит Run & Drive?', 'Подобрать запчасть', 'Что это за запчасть?'];
    return Scaffold(
      appBar: AppBar(title: const Text('AI-помощник')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Wrap(spacing: 8, runSpacing: 8, children: chips.map((e) => ActionChip(label: Text(e), onPressed: () => setState(() => c.text = e))).toList()),
          const SizedBox(height: 8),
          TextField(controller: c, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'Ваш вопрос', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() => loading = true);
                  final msg = await service.chat(message: c.text);
                  setState(() {
                    answer = msg.text;
                    actions = msg.actions;
                    loading = false;
                  });
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
}
