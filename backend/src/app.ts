import cors from "cors";
import express from "express";
import { healthRouter } from "./routes/health.routes";
import { produtosRouter } from "./modules/produtos/produtos.routes";
import { artesasRouter } from "./modules/artesas/artesas.routes";
import { exportacaoRouter } from "./modules/exportacao/exportacao.routes";
import { mensagensRouter } from "./modules/mensagens/mensagens.routes";
import { cadastroRouter } from "./modules/cadastro/cadastro.routes";

export const app = express();

app.use(cors());
app.use(express.json());

app.use(healthRouter);
app.use("/api/produtos", produtosRouter);
app.use("/api/artesas", artesasRouter);
app.use("/api/exportacao", exportacaoRouter);
app.use("/api/mensagens", mensagensRouter);
app.use("/api/cadastro", cadastroRouter);
