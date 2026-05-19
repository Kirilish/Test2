import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import OpenAI from 'openai';

const app = express();

app.use(cors());
app.use(express.json({ limit: '15mb' }));

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

app.post('/api/ai/chat', async (req, res) => {
  try {
    const { message, image_base64 } = req.body || {};

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'message is required' });
    }

    if (!process.env.OPENAI_API_KEY) {
      return res.status(500).json({
        error: 'missing_openai_api_key',
        details: 'OPENAI_API_KEY is not set in .env',
      });
    }

    const content = [
      {
        type: 'input_text',
        text: message,
      },
    ];

    if (
      image_base64 &&
      typeof image_base64 === 'string' &&
      image_base64.trim().length > 0
    ) {
      const imageUrl = image_base64.startsWith('data:image')
        ? image_base64
        : `data:image/jpeg;base64,${image_base64}`;

      content.push({
        type: 'input_image',
        image_url: imageUrl,
        detail: 'auto',
      });
    }

    const input = [
      {
        role: 'system',
        content:
          'Ты авто-ассистент Zapshop. Не обещай 100% совместимость без VIN/OEM. Всегда предупреждай о проверке VIN/OEM и маркировок.',
      },
      {
        role: 'user',
        content,
      },
    ];

    const response = await client.responses.create({
      model: 'gpt-4.1-mini',
      input,
      temperature: 0.3,
    });

    const text = response.output_text || 'Не удалось получить ответ.';

    res.json({
      text,
      actions: ['Открыть маркет', 'Оставить заявку'],
    });
  } catch (e) {
    console.error('AI proxy error:', e);

    res.status(500).json({
      error: 'ai_proxy_error',
      details: e?.message || 'unknown_error',
    });
  }
});


app.post('/api/orders/telegram', async (req, res) => {
  try {
    const token = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;
    if (!token || !chatId) {
      return res.status(500).json({ error: 'missing_telegram_config' });
    }

    const { total, items } = req.body || {};
    const lines = (items || []).map((x) => {
      const p = x.part || {};
      return `• ${p.title || '-'} x${x.quantity || 1} (${p.price || '-'} ${p.currency || ''})`;
    });
    const text = `Новый заказ из приложения Zapshop Garage\nИтого: ${total || 0} USD\n${lines.join('\n')}`;

    await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: chatId, text }),
    });

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'telegram_send_error', details: e?.message || 'unknown_error' });
  }
});

app.get('/health', (_, res) => {
  res.json({ ok: true });
});

const port = Number(process.env.PORT || 8080);

app.listen(port, () => {
  console.log(`AI proxy started on http://localhost:${port}`);
});
