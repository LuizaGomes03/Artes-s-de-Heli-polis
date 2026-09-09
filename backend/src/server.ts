import { app } from "./app";
import { env } from "./config/env";
import { connectDatabase } from "./config/database";

async function bootstrap(): Promise<void> {
  await connectDatabase();

  app.listen(env.port, () => {
    console.log(`[server] Rodando em http://localhost:${env.port}`);
  });
}

bootstrap().catch((error) => {
  console.error("[server] Falha ao iniciar:", error);
  process.exit(1);
});
