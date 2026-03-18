import mongoose from "mongoose";

const connectDB = async () => {
  try {
    const dbURI = `${process.env.MONGODB_URI}/prescripto`;

    await mongoose.connect(dbURI);

    console.log("✅ MongoDB Connected Successfully to database: prescripto");
    console.log("📊 Available collections:", await mongoose.connection.db.listCollections().toArray());
  } catch (error) {
    console.error("❌ MongoDB Connection Error:", error.message);
    process.exit(1);
  }
};

// Optional listeners (for debugging)
mongoose.connection.on("disconnected", () => {
  console.log("⚠️ MongoDB Disconnected");
});

mongoose.connection.on("error", (err) => {
  console.error("❌ MongoDB Error:", err);
});

export default connectDB;
