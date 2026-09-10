## Estrutura

```
.
├── frontend/          # App Flutter (Dart) - interface do usuário, multiplataforma
│   └── chat_backend/  # API Node.js + Express - assistente virtual do chat
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
cp .env.example .env   # ajuste PORT e MONGODB_URI se necessário
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

## Backend do chat (Node.js + Express)

Servidor separado que alimenta o assistente virtual exibido no app.

```
cd frontend/chat_backend
npm install
cp .env.example .env   # configure a chave de API do assistente e a porta
node server.js
```

Roda por padrão em `http://127.0.0.1:3001`.

Rota principal: `POST /api/chat`

> ⚠️ Para o assistente funcionar dentro do app, esse servidor precisa estar rodando **junto** com o backend principal. A URL usada pelo app é definida em `frontend/lib/app/features/home/pages/current_home_page.dart` (variável `_chatApiUrl`), com valor padrão `http://127.0.0.1:3001/api`.

## Rodando o projeto completo

São necessários **3 terminais** abertos ao mesmo tempo:

1. **Backend principal** (porta 3000): `cd backend && npm run dev`
2. **Backend do chat** (porta 3001): `cd frontend/chat_backend && node server.js`
3. **App Flutter**: `cd frontend && flutter run`
