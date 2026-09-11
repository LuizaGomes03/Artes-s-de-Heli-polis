## Estrutura

```
.
├── frontend/          # App Flutter (Dart) - interface do usuário, multiplataforma
└── backend/           # API Node.js + TypeScript + Express + MongoDB (Mongoose)
```

## Frontend (Flutter)

```
cd frontend
flutter pub get
flutter run
```

## Backend principal (Node.js + TypeScript + MongoDB)

```
cd backend
npm install
cp .env.example .env   # ajuste PORT, MONGODB_URI e GROQ_API_KEY se necessário
npm run dev
```

Endpoint de verificação: `GET /health`

Roda por padrão em `http://localhost:3000`.

Rotas da API (em construção):
- `/api/produtos`
- `/api/artesas`
- `/api/exportacao`
- `/api/mensagens`
- `/api/cadastro`
- `/api/chat`

> ⚠️ A rota `/api/chat` alimenta o assistente virtual exibido no app e depende da variável `GROQ_API_KEY` configurada no `.env` do backend. A URL usada pelo app é definida em `frontend/lib/app/features/home/pages/current_home_page.dart` (variável `_chatApiUrl`), com valor padrão `http://127.0.0.1:3000/api`.

## Rodando o projeto completo

São necessários **2 terminais** abertos ao mesmo tempo:

1. **Backend principal** (porta 3000): `cd backend && npm run dev`
2. **App Flutter**: `cd frontend && flutter run`
