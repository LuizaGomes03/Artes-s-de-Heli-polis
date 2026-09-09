import "dotenv/config";

export const env = {
  port: Number(process.env.PORT) || 3000,
  mongodbUri: process.env.MONGODB_URI || "mongodb://localhost:27017/artesas-de-heliopolis",
};
