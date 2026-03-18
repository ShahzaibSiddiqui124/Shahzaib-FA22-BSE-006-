// ==========================
// 📁 server.js
// ==========================

import express from "express";
import cors from "cors";
import 'dotenv/config';
import connectDB from "./config/mongodb.js";
// import connectCloudinary from "./config/cloudinary.js"; // <--- DISABLED
import userRouter from "./routes/userRoute.js";
import doctorRouter from "./routes/doctorRoute.js";
import adminRouter from "./routes/adminRoute.js";

// ✅ Initialize app
const app = express();
const port = process.env.PORT || 4000;

// ✅ Connect to Database
connectDB();
// connectCloudinary(); // <--- DISABLED

// ✅ Middleware
app.use(express.json());
app.use(cors());

// ✅ Make "uploads" folder public (NEW)
// This allows the frontend to view images at http://localhost:4000/uploads/filename.jpg
app.use('/uploads', express.static('uploads'))

// ✅ API Routes
app.use("/api/user", userRouter);
app.use("/api/doctor", doctorRouter);
app.use("/api/admin", adminRouter);

// ✅ Health check route
app.get("/", (req, res) => {
  res.send("✅ Hospital Management API is Working");
});

// ✅ Start server only if not in test mode
if (process.env.NODE_ENV !== "test") {
  app.listen(port, () => {
    console.log(`🚀 Server started on PORT: ${port}`);
  });
}

// ✅ Export app for testing
export default app;