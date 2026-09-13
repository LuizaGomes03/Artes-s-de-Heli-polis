import multer from "multer";
import path from "path";
import fs from "fs";

const pastaUploads = path.resolve(__dirname, "../../uploads/produtos");

// Garante que a pasta existe
if (!fs.existsSync(pastaUploads)) {
  fs.mkdirSync(pastaUploads, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, pastaUploads);
  },
  filename: (_req, file, cb) => {
    const sufixo = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const extensao = path.extname(file.originalname);
    cb(null, `${sufixo}${extensao}`);
  },
});

function filtroDeArquivo(_req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) {
  const tiposPermitidos = ["image/jpeg", "image/png", "image/webp"];
  if (!tiposPermitidos.includes(file.mimetype)) {
    return cb(new Error("formato de imagem não suportado (use jpg, png ou webp)"));
  }
  cb(null, true);
}

export const upload = multer({
  storage,
  fileFilter: filtroDeArquivo,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB por foto
});