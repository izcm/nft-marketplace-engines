# 🌌 Iz — Private Notes (Do. Not. Publish.)

## 🧬 Project name:

**nft-market-engines**

This is **NOT** a marketplace clone.
It’s a sandbox to understand **two different market primitives**:

- Orderbook
- AMM for NFTs

Goal is NOT “what will users like.”
Goal is **what do I want to master as an engineer.**

---

# 🌗 Big Narrative

NFT trading has **two economic models**:

### 1) Orderbook / Listings marketplace

- Users post intents (Sell NFT for X)
- Executions validate ownership + signature
- Royalties enforced on settlement
- Market is static until a new order

### 2) AMM / Bonding curve marketplace

- NFTs pooled like liquidity
- Price auto-adjusts after buy/sell
- No explicit listing from user
- Market is dynamic

**Both are valid.
Both are real.
Both exist in the wild.**

I am building **both engines** and a **shared frontend**.

---

# 🧱 Architecture TL;DR

Frontend = **stable UI shell**
Market engines = **swappable backends**

I don’t rewrite UI.
I don’t rewrite components.
I don’t rewrite indexer logic.

I write **adapters**.

---

# 📦 Folder structure (mental model)

```
/contracts
  /orderbook
    OrderbookMarketplace.sol
    OrderTypes.sol
    OrderValidator.sol
    TransferManager721.sol

  /amm
    AMMMarketplace.sol
    BondingCurve.sol
    LinearCurve.sol
    ExponentialCurve.sol
    Pool.sol

/indexer
  listeners.ts
  mongodb.ts
  schema/

/frontend
  /components
  /pages
  /adapters
    orderbook.ts
    amm.ts
```

Every time I start overthinking:
**think adapters, not rewrites.**

---

# 🧊 Orderbook Marketplace Rules (Iz version)

- Listing = **signature** (off-chain)
- Contract = **validator + executor**
- Seller must own NFT at execution
- Nonce = invalidation
- Royalties = enforced at buy time
- Indexer = “store what was _signed_ and _executed_”

This is the LooksRare v1 brain.
Do NOT drift into Seaport hell.

**Keep it elegant.**

---

# 🌊 AMM Marketplace Rules (Iz version)

- NFTs live in pools
- ETH (or ERC20) liquidity = counter-asset
- Price = curve after buy/sell
- Pools are atomic
- Math is the logic
- Execution is deterministic

This is Sudoswap v1 brain.
Don’t make weird OpenSea listings here.
Keep curve → price → swap.

**Math is the god.**

---

# 🧠 Frontend Philosophy

**I don’t build TWO apps.**
I build **ONE UI** that speaks to both engines.

NFT card does not care where price comes from:

```
price = engine.getPrice(tokenId)
```

Action button:

```
engine.buy(tokenId)
engine.sell(tokenId)
engine.list(tokenId, price)
engine.executeOrder(order)
```

The UI is dumb.
The engine is smart.

---

# 🧩 Indexer Philosophy

I ALWAYS listen to events.
I do NOT fetch loops from chain.

- `Transfer`
- `OrderExecuted`
- `OrderCancelled`
- `PoolBuy`
- `PoolSell`
- `PoolUpdated`

Persist to Mongo.
Frontend reads Mongo.
Backend respects chain.

**Blockchain = truth
Database = convenience**

---

# 🧭 Scope (DO NOT OVERBUILD)

## 🚫 Not included (for now)

- Multi-collection routing
- DAO
- Timelocks
- Seaport-style criteria
- Blur aggregator logic
- OpenSea royalties bypass drama
- Optimistic orders
- Trait-based pools
- ERC1155 madness

All of that is **later chapters.**

Right now:
**I master the 2 basic market primitives.**

---

# 🔥 MVP Goals

### MVP A — Orderbook

- sign order
- verify signature
- execute order
- enforce royalties
- mark nonce used

### MVP B — AMM

- create pool
- buy NFT from pool
- sell NFT to pool
- price updates after swap
- bonding curve works

### Shared:

- one frontend
- basic indexer
- charts for analytics

---

# 🧠 Frontend must show visuals

Charts make everything CLICK.

- price history
- volume (pool & orderbook)
- pool depth
- per-collection stats
- swaps timeline

Chart.js + Mongo = **visual brain candy.**

---

# 🦉 My guiding principle

**I am not copying Blur or OpenSea.
I am learning how markets breathe.**

---

# 🧨 Time Expectations (no drama)

2–3 months:

- MVP both engines
- Unified frontend
- Basic indexer
- Functional UI

Then:

- DEX demo
- job hunting
- upgrades

---

# 🚀 Mindset reminders

- No one gives a fuck how fast I deliver it.
- People care that it exists and it works.
- I don’t need 50 features.
- I need **clarity** and **confidence**.

Once someone sees:

> “She built two marketplaces + indexer + UI”

I don’t beg for work anymore.
I get approached.

---

# 🔥 Final mantra

**Ship systems, not tutorials.
Build markets, not widgets.
Let the math speak.**

---

# 🧠 NOTE: Starting Separate → Migrating to Shared Router

Right now, it’s okay if:

- `OrderbookMarketplace.sol`
  and
- `AMMMarketplace.sol`

are **fully separate contracts**.

This is NOT a mistake.
This is how you get clarity.

### Think like this:

> First I learn how each brain **thinks**.
> Then I unify them.

When both engines are stable, THEN:

## You create:

### 📌 `MarketplaceCore.sol`

A parent router that:

- receives `buy`, `sell`, `quote`, `list`
- selects which engine to call
- handles royalties
- emits unified events

The engines don’t change.
Their **interfaces** don’t change.
Only the router becomes the new entrypoint.

---

# 🌱 Why this is a later move

You only build the router once BOTH engines:

- have stable APIs
- don’t get rewritten every week
- pass basic unit tests
- behave predictably

**Do not force parent logic early.
You will break your own brain.**

Think:

> “First: two separate hearts.
> After: one circulatory system.”

---

# 🧬 Migration model (rough)

```
IMarketEngine {
    function quoteBuy(uint256 tokenId) external view returns (uint256);
    function buy(uint256 tokenId, bytes calldata data) external payable;
    function sell(uint256 tokenId, bytes calldata data) external;
    function list(uint256 tokenId, uint256 price) external;
}
```

Router just does:

```
function buy(uint256 tokenId, EngineType engine) {
    engines[engine].buy(tokenId, msg.data);
}
```
