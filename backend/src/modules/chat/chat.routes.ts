import express, { Router } from "express";
import rateLimit from "express-rate-limit";
import { env } from "../../config/env";
import { askChat, ChatError, normalizeMessages } from "./chat.service";
import type { ChatLanguage, ChatRequestBody } from "./chat.types";

export const chatRouter = Router();

const VALID_LANGUAGES: ChatLanguage[] = ["pt", "en", "es"];

chatRouter.use(express.json({ limit: "64kb" }));

const chatRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
});

chatRouter.get("/", (_req, res) => {
  res.json({
    ok: true,
    service: "artesas-heliopolis-chat",
    model: env.groqModel,
  });
});

chatRouter.post(
  "/",
  chatRateLimiter,
  async (req, res) => {
    try {
      const body = req.body as ChatRequestBody;

      const language: ChatLanguage = VALID_LANGUAGES.includes(
        body?.language as ChatLanguage
      )
        ? (body.language as ChatLanguage)
        : "pt";

      const history = normalizeMessages(body?.messages);

      if (!history.length) {
        return res.status(400).json({ error: "Envie pelo menos uma mensagem." });
      }

      const reply = await askChat(language, history);
      return res.json({ reply });
    } catch (error) {
      if (error instanceof ChatError) {
        return res.status(error.status).json({ error: error.message });
      }

      console.error(error);
      return res.status(500).json({
        error: "Erro interno no servidor de atendimento.",
      });
    }
  }
);
