import { env } from "../../config/env";
import type { ChatLanguage, ChatMessage } from "./chat.types";

export const SYSTEM_PROMPT = `
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

const LANGUAGE_INSTRUCTIONS: Record<ChatLanguage, string> = {
  pt: "Responda em português brasileiro.",
  en: "Respond in English.",
  es: "Responde en español.",
};

export class ChatError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

export function normalizeMessages(messages: unknown): ChatMessage[] {
  if (!Array.isArray(messages)) return [];

  return messages
    .filter(
      (m): m is ChatMessage =>
        !!m &&
        (m.role === "user" || m.role === "assistant") &&
        typeof m.content === "string"
    )
    .slice(-20)
    .map((m) => ({
      role: m.role,
      content: m.content.slice(0, 4000),
    }));
}

export function extractText(response: any): string {
  return (response?.choices?.[0]?.message?.content || "").trim();
}

export async function askChat(
  language: ChatLanguage,
  messages: ChatMessage[]
): Promise<string> {
  if (!env.groqApiKey) {
    throw new ChatError("GROQ_API_KEY não configurada no servidor.", 500);
  }

  const languageInstruction = LANGUAGE_INSTRUCTIONS[language];

  const response = await fetch(
    "https://api.groq.com/openai/v1/chat/completions",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.groqApiKey}`,
      },
      body: JSON.stringify({
        model: env.groqModel,
        messages: [
          { role: "system", content: `${SYSTEM_PROMPT}\n\n${languageInstruction}` },
          ...messages,
        ],
        max_tokens: 700,
      }),
    }
  );

  const data = await response.json();

  if (!response.ok) {
    console.error("Groq error:", JSON.stringify(data));
    throw new ChatError(
      "Não foi possível obter uma resposta do assistente.",
      response.status
    );
  }

  const reply = extractText(data);
  if (!reply) {
    throw new ChatError("O assistente retornou uma resposta vazia.", 502);
  }

  return reply;
}
