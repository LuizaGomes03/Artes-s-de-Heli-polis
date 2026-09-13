import cors from "cors";
import express from "express";
import path from "path";
import { healthRouter } from "./routes/health.routes";
import { produtosRouter } from "./modules/produtos/produtos.routes";
import { artesasRouter } from "./modules/artesas/artesas.routes";
import { exportacaoRouter } from "./modules/exportacao/exportacao.routes";
import { mensagensRouter } from "./modules/mensagens/mensagens.routes";
import { cadastroRouter } from "./modules/cadastro/cadastro.routes";
import { chatRouter } from "./modules/chat/chat.routes";

export const app = express();

app.use(cors());

// Montado antes do parser global para que o limite de payload de 64kb
// definido dentro do chatRouter seja o que efetivamente se aplica a essa rota.
app.use("/api/chat", chatRouter);

app.use(express.json());

app.use(healthRouter);
app.use("/api/produtos", produtosRouter);
app.use("/api/artesas", artesasRouter);
app.use("/api/exportacao", exportacaoRouter);
app.use("/api/mensagens", mensagensRouter);
app.use("/api/cadastro", cadastroRouter);

app.use("/uploads", express.static(path.resolve(__dirname, "../uploads")));
