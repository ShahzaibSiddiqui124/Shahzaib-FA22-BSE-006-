import request from "supertest";
import app from "../server.js";

describe("👨‍⚕️ Doctor API Tests", () => {
  test("Fetch doctor list", async () => {
    const res = await request(app).get("/api/doctor/list");
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty("success");
  });

  test("Filter doctors by specialization", async () => {
    const res = await request(app).get("/api/doctor/filter?specialization=Cardiology");
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty("success");
  });
});
