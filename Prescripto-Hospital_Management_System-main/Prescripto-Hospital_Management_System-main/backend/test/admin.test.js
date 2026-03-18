import request from "supertest";
import app from "../server.js";

describe("🧑‍💼 Admin API Tests", () => {
  let token;

  test("Admin login", async () => {
    const res = await request(app)
      .post("/api/admin/login")
      .send({
        email: process.env.ADMIN_EMAIL,
        password: process.env.ADMIN_PASSWORD
      });
    expect(res.body.success).toBe(true);
    token = res.body.token;
  });

  test("Get all doctors (Authorized)", async () => {
    const res = await request(app)
      .get("/api/admin/all-doctors")
      .set("Authorization", `Bearer ${token}`);
    expect(res.body).toHaveProperty("success");
  });
});
