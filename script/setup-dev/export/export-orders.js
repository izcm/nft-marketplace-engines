// script assumes a running local / external backend
import { readFile } from "node:fs/promises";

const server = "http://localhost:5000/api/orders";

const inFile = "./data/1337/orders-sanitized.json";

const raw = await readFile(inFile, "utf8");

const obj = JSON.parse(raw);
const orders = obj.signedOrders;

orders.map(async (order) => {
  console.log(order);
  const payload = await fetch(server, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify(order),
  });
});

console.log("Orders exported ✔");
