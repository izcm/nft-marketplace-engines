# ───────────────────────────────────────────────
#   Marketplace Engines Makefile
# ───────────────────────────────────────────────

# Variables
include .env

# paths
DEPLOY_ORDER_ENGINE = script/DeployOrderEngine.s.sol
PATH_DEV = script/dev
PATH_BOOTSTRAP = $(PATH_DEV)/bootstrap
PATH_ORDERS = $(PATH_DEV)/orders
PATH_EXPORT = $(PATH_DEV)/export

WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

# ───────────────────────────────────────────────
#   DEV — PRIMARY ENTRYPOINTS
# ───────────────────────────────────────────────
dev-start: dev-fork dev-bootstrap-accounts dev-deploy-core dev-bootstrap-nfts dev-approve
	@echo "🚀 Dev environment ready"

dev-reset: kill-anvil dev-start
	@echo "♻️ Dev reset complete"

# ───────────────────────────────────────────────
#   DEV ENV SETUP - ON CHAIN
# ───────────────────────────────────────────────
dev-fork:
	@echo "🧬 Starting anvil fork..."
	@cd $(PATH_DEV) && bash start.sh

dev-build-orders:
	@echo "🔨 Building orders..."
	forge script $(PATH_ORDERS)/BuildOrders.s.sol \
		--rpc-url http://127.0.0.1:8545 \
		--broadcast \
		--sender $(SENDER) \
		--private-key $(PRIVATE_KEY)

dev-bootstrap-accounts:
	@echo "💻 Bootstrapping dev accounts..."
	forge script $(PATH_BOOTSTRAP)/BootstrapAccounts.s.sol \
		--rpc-url http://127.0.0.1:8545 \
		--broadcast \
		--sender $(SENDER) \
		--private-key $(PRIVATE_KEY)

dev-deploy-core:
	@echo "🧾 Deploying core contracts..."
	forge script $(PATH_DEV)/DeployCore.s.sol \
		--rpc-url http://127.0.0.1:8545 \
		--broadcast \
		--sender $(SENDER) \
		--private-key $(PRIVATE_KEY)

dev-bootstrap-nfts:
	@echo "🖼️ Bootstrapping NFTs..."
	forge script $(PATH_BOOTSTRAP)/BootstrapNFTs.s.sol \
		--rpc-url http://127.0.0.1:8545 \
		--broadcast \
		--sender $(SENDER) \
		--private-key $(PRIVATE_KEY)

dev-approve:
	@echo "✔ Executing approvals..."
	forge script $(PATH_BOOTSTRAP)/Approve.s.sol \
		--rpc-url http://127.0.0.1:8545 \
		--broadcast \
		--sender $(SENDER) \
		--private-key $(PRIVATE_KEY)

# ───────────────────────────────────────────────
#   DEV ENV SETUP - OFF CHAIN ORDERS
# ───────────────────────────────────────────────
dev-sanitize-orders:
	@echo "🧽 Sanitizing orders..."
	node $(PATH_EXPORT)/sanitize-orders.js

dev-export-orders: dev-sanitize-orders
	@echo "📩 Exporting orders..."
	node $(PATH_EXPORT)/export-orders.js

# ───────────────────────────────────────────────
#   RESET / PROCESS CONTROL
# ───────────────────────────────────────────────
kill-anvil:
	@echo "💀 Killing anvil..."
	pkill anvil 2>/dev/null || true

# ───────────────────────────────────────────────
#   CHAIN READ / WRITE HELPERS
# ───────────────────────────────────────────────
weth-balance:
	@if [ -z "$(ADDR)" ]; then \
		echo "❌ Missing ADDR. Usage: make weth-balance ADDR=0xYourAddress"; \
		exit 1; \
	fi
	@echo "WETH balance for $(ADDR):"
	@cast call \
		$(WETH) \
		"balanceOf(address)" \
		$(ADDR) \
		--rpc-url http://127.0.0.1:8545 | cast from-wei

# ───────────────────────────────────────────────
#   ETC.
# ───────────────────────────────────────────────
tree:
	@if [ -z "$(DEPTH)" ]; then DEPTH=3; fi; \
	tree -L $$DEPTH -I "out|lib|broadcast|cache|notes"
