import { Schema, model, type Document } from "mongoose";
import bcrypt from "bcrypt";

export interface IArtesa extends Document {
  nome: string;
  email: string;
  senha: string;
  telefone?: string;
  bio?: string;
  compararSenha(senhaDigitada: string): Promise<boolean>;
}

const artesaSchema = new Schema<IArtesa>(
  {
    nome: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    senha: { type: String, required: true },
    telefone: { type: String },
    bio: { type: String },
  },
  { timestamps: true }
);

// Antes de salvar, transforma a senha em hash (só se ela mudou)
artesaSchema.pre("save", async function (next) {
  if (!this.isModified("senha")) return next();
  this.senha = await bcrypt.hash(this.senha, 10);
  next();
});

// Método pra comparar senha digitada no login com o hash salvo
artesaSchema.methods.compararSenha = function (senhaDigitada: string) {
  return bcrypt.compare(senhaDigitada, this.senha);
};

export const Artesa = model<IArtesa>("Artesa", artesaSchema);