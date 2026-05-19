import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import OpenAI from 'openai';

const app = express();
app.use(cors());
app.use(express.json({ limit: '15mb' }));

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

app.post('/api/ai/chat', async (req, res) => {
  try {
    const { message, image_base64 } = req.body || {};
    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'message is required' });
    }

    const input = [
      {
        role: 'system',
        content:
          'Ты авто-ассистент Zapshop. Не обещай 100% совместимость без VIN/OEM. Всегда предупреждай о проверке VIN/OEM и маркировок.',
      },
      {
        role: 'user',
        content: [
          { type: 'input_text', text: message },
          if (image_base64 != null && image_base64.toString().isNotEmpty)
            {
              type: 'input_image',
              image_url: `data:image/jpeg;base64,${image_base64}`,
            },
        ],
      },
    ];

    const response = await client.responses.create({
      model: 'gpt-4.1-mini',
      input,
      temperature: 0.3,
    });

    const text = response.output_text || 'Не удалось получить ответ.';
    res.json({ text, actions: ['Открыть маркет', 'Оставить заявку'] });
  } catch (e) {
    res.status(500).json({ error: 'ai_proxy_error', details: e?.message || 'unknown_error' });
  }
});

app.get('/health', (_, res) => res.json({ ok: true }));

const port = Number(process.env.PORT || 8080);
app.listen(port, () => {
  console.log(`AI proxy started on http://localhost:${port}`);
});
