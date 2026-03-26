import { Elysia, t } from "elysia";
import { swagger } from "@elysiajs/swagger";
import { cors } from "@elysiajs/cors";

const app = new Elysia()
  .use(cors())
  .use(swagger())
  .get("/", () => "Welcome to NoteCraft API!")
  .group("/api", (app) =>
    app
      .get("/leaderboard", () => {
        return [
          { name: "John Doe", score: 100 },
          { name: "Jane Doe", score: 90 },
          { name: "Bob Smith", score: 80 },
        ];
      })
      .get("/profile", () => {
        return {
          name: "Player name",
          learningHours: 3,
          since: "19 March 2026",
          coins: 53,
          rank: 2,
        };
      })
  )
  .listen(3000);

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`
);