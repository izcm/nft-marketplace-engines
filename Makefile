# ───────────────────────────────────────────────
#   Marketplace Engines Makefile 
# ───────────────────────────────────────────────

# Variables
include .env

# paths
DEPLOY_ORDER_ENGINE = script/DeployOrderEngine.s.sol
PATH_FORK_SETUP_SCRIPTS = script/setup-fork

# ───────────────────────────────────────────────
#   Deploy 
# ───────────────────────────────────────────────
deploy-orderbook-fork: 
	@echo "🚀 Deploying OrderEngine..."
	@forge script $(DEPLOY_ORDER_ENGINE) \
		--rpc-url fork \
		--broadcast \
		--sender $(ANVIL_SENDER) \
		--private-key $(ANVIL_PK) \
		| tee $(PATH_FORK_SETUP_SCRIPTS)/deploy-engine.log 


