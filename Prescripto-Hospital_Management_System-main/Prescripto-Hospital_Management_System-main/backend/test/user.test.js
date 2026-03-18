import request from "supertest";
import app from "../server.js"; // import your Express app

describe("🧍 User API Tests", () => {
  let token;

  test("Register a new user", async () => {
    const res = await request(app)
      .post("/api/user/register")
      .send({
        name: "Test User",
        email: `test${Date.now()}@gmail.com`,
        password: "password123"
      });
    expect(res.body.success).toBe(true);
    token = res.body.token;
  });

  test("Login user", async () => {
    const res = await request(app)
      .post("/api/user/login")
      .send({
        email: "testuser@gmail.com", // replace with a valid test user
        password: "password123"
      });
    expect(res.body).toHaveProperty("success");
  });

  test("Get profile (Authorized)", async () => {
    const res = await request(app)
      .post("/api/user/get-profile")
      .set("Authorization", `Bearer ${token}`)
      .send({ userId: "dummy" });
    expect(res.body).toHaveProperty("success");
  });
});
