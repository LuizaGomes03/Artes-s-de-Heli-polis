import 'dotenv/config';
import cors from 'cors';
import express from 'express';

const app = express();
const port = Number(process.env.PORT || 3000);
const model = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';

app.use(cors());
app.use(express.json({ limit: '64kb' }));

const SYSTEM_PROMPT = `
Você é a assistente virtual oficial da plataforma Artesãs de Heliópolis.

OBJETIVO
Ajudar de forma acolhedora, clara e prática principalmente quando a pessoa estiver com um problema ou dúvida na plataforma.

PÚBLICO
- Artesãs: cadastro, perfil, publicação de produtos, fotos, preços, vendas, pedidos, exportação e funcionamento da plataforma.
- Compradores: cadastro, produtos, compras, pagamentos, pedidos, entrega, troca, reembolso e contato com suporte.

REGRAS
1. Responda no idioma solicitado: pt = português brasileiro, en = inglês, es = espanhol.
2. Seja objetiva, mas explique os passos necessários.
3. Não invente status de pedido, valores, prazos, políticas, produtos ou informações de contas.
4. Se a informação não estiver disponível, diga claramente que não consegue verificar aquele dado e oriente a pessoa a procurar o suporte.
5. Nunca peça senha, código de autenticação, chave PIX, dados completos de cartão ou outros segredos.
6. Para problemas de pedido, primeiro descubra o que aconteceu e sugira os próximos passos.
7. Se houver risco de fraude, pagamento suspeito, ameaça, assédio ou exposição de dados pessoais, recomende interromper a ação e procurar o suporte da plataforma.
8. Não diga que é humana. Você é uma assistente virtual.
9. Não prometa que uma ação foi executada se você não tiver uma ferramenta para executá-la.
10. Quando a pergunta for sobre exportação, explique de forma geral e deixe claro quando documentos, regras ou valores precisam ser confirmados com a equipe responsável.

ESTILO
- Tom acolhedor e profissional.
- Use listas numeradas quando houver passos.
- Evite textos muito longos.
- Faça uma pergunta de esclarecimento quando faltar informação essencial.
`;

function normalizeMessages(messages) {
  if (!Array.isArray(messages)) return [];

  return messages
    .filter((m) => m && (m.role === 'user' || m.role === 'assistant') && typeof m.content === 'string')
    .slice(-20)
    .map((m) => ({
      role: m.role,
      content: m.content.slice(0, 4000),
    }));
}

function extractText(response) {
  return (response?.choices?.[0]?.message?.content || '').trim();
}

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'artesas-heliopolis-chat', model });
});

app.post('/api/chat', async (req, res) => {
  try {
    if (!process.env.GROQ_API_KEY) {
      return res.status(500).json({
        error: 'GROQ_API_KEY não configurada no servidor.',
      });
    }

    const language = ['pt', 'en', 'es'].includes(req.body?.language)
      ? req.body.language
      : 'pt';
    const history = normalizeMessages(req.body?.messages);

    if (!history.length) {
      return res.status(400).json({ error: 'Envie pelo menos uma mensagem.' });
    }

    const languageInstruction = {
      pt: 'Responda em português brasileiro.',
      en: 'Respond in English.',
      es: 'Responde en español.',
    }[language];

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: `${SYSTEM_PROMPT}\n\n${languageInstruction}` },
          ...history,
        ],
        max_tokens: 700,
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error('Groq error:', JSON.stringify(data));
      return res.status(response.status).json({
        error: 'Não foi possível obter uma resposta do assistente.',
      });
    }

    const reply = extractText(data);
    if (!reply) {
      return res.status(502).json({ error: 'O assistente retornou uma resposta vazia.' });
    }

    return res.json({ reply });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      error: 'Erro interno no servidor de atendimento.',
    });
  }
});

app.listen(port, () => {
  console.log(`Artesãs de Heliópolis Chat API: http://127.0.0.1:${port}`);
});