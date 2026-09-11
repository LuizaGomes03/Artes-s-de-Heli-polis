export type ChatRole = "user" | "assistant";

export type ChatLanguage = "pt" | "en" | "es";

export interface ChatMessage {
  role: ChatRole;
  content: string;
}

export interface ChatRequestBody {
  language?: ChatLanguage;
  messages?: ChatMessage[];
}
