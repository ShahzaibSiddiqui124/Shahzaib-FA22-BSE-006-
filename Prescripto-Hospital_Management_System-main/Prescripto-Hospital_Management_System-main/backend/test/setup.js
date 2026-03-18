import mongoose from "mongoose";
import dotenv from "dotenv";
dotenv.config();

beforeAll(async () => {
  const dbUrl = process.env.MONGODB_URI_TEST || `${process.env.MONGODB_URI}-test`;
  await mongoose.connect(dbUrl);
});

afterAll(async () => {
  await mongoose.connection.close();
});
