import { Router } from "express";
import jwt from "jsonwebtoken";
import { Artesa } from "../artesas/artesas.model";
import { env } from "../../config/env";

export const cadastroRouter = Router();

// POST /api/cadastro/registro
cadastroRouter.post("/registro", async (req, res) => {
  try {
    const { nome, email, senha, telefone, bio } = req.body;

    if (!nome || !email || !senha) {
      return res.status(400).json({ erro: "nome, email e senha são obrigatórios" });
    }

    const jaExiste = await Artesa.findOne({ email });
    if (jaExiste) {
      return res.status(409).json({ erro: "já existe uma artesã cadastrada com esse email" });
    }

    const artesa = await Artesa.create({ nome, email, senha, telefone, bio });

    const token = jwt.sign({ id: artesa._id }, env.jwtSecret!, { expiresIn: "7d" });

    res.status(201).json({
      token,
      artesa: { id: artesa._id, nome: artesa.nome, email: artesa.email },
    });
  } catch (erro) {
    res.status(500).json({ erro: "erro ao criar cadastro" });
  }
});

// POST /api/cadastro/login
cadastroRouter.post("/login", async (req, res) => {
  try {
    const { email, senha } = req.body;

    if (!email || !senha) {
      return res.status(400).json({ erro: "email e senha são obrigatórios" });
    }

    const artesa = await Artesa.findOne({ email });
    if (!artesa) {
      return res.status(401).json({ erro: "email ou senha inválidos" });
    }

    const senhaCorreta = await artesa.compararSenha(senha);
    if (!senhaCorreta) {
      return res.status(401).json({ erro: "email ou senha inválidos" });
    }

    const token = jwt.sign({ id: artesa._id }, env.jwtSecret!, { expiresIn: "7d" });

    res.json({
      token,
      artesa: { id: artesa._id, nome: artesa.nome, email: artesa.email },
    });
  } catch (erro) {
    res.status(500).json({ erro: "erro ao fazer login" });
  }
});