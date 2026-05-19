import 'package:flutter/material.dart';

abstract class AiService {
  Future<String> chat(String message);
}

class MockAiService implements AiService {
  @override
  Future<String> chat(String message) async {
    // TODO: Replace MockAiService with real backend AI proxy using OpenAI Responses API.
    final q = message.toLowerCase();
    if (q.contains('фара') || q.contains('бампер') || q.contains('двигатель') || q.contains('коробка')) {
      return 'Уточните VIN/OEM, сторону детали и комплектацию. Могу предложить открыть маркет или оставить заявку. Для точного подбора нужно сверить VIN, OEM, комплектацию и фото старой детали.';
    }
    return 'Проверьте историю обслуживания, каталожный номер и состояние б/у детали. Для точного подбора нужно сверить VIN, OEM, комплектацию и фото старой детали.';
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
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final chips = ['Что проверить перед покупкой двигателя?', 'Нужна фара', 'Нужен бампер', 'Что значит Run & Drive?', 'Подобрать запчасть'];
    return Scaffold(
      appBar: AppBar(title: const Text('AI-помощник')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Wrap(spacing: 8, children: chips.map((e) => ActionChip(label: Text(e), onPressed: () => setState(() => c.text = e))).toList()),
          TextField(controller: c, decoration: const InputDecoration(hintText: 'Ваш вопрос')),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: () async {
                setState(() => loading = true);
                answer = await service.chat(c.text);
                setState(() => loading = false);
              },
              child: const Text('Спросить')),
          if (loading) const CircularProgressIndicator(),
          if (!loading) Expanded(child: SingleChildScrollView(child: Text(answer)))
        ]),
      ),
    );
  }
}
