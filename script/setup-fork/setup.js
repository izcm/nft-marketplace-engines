import { execSync } from "child_process";

// ---- CONFIG ----
const WALLET = process.env.WALLET;
const BAYC = "0xBC4CA0eda7647A8ab7C2061c2E118A18a936f13D"; // BAYC mainnet contract

// --- READ MARKETPLACE FROM DEPLOYMENT OUTPUT ---
const readLogs = () => {};

readLogs();

// --- LINKS ---
// https://ethereum.org/developers/docs/apis/json-rpc/
// https://getfoundry.sh/anvil/reference/
// https://v2.hardhat.org/hardhat-network/docs/reference#hardhat-network-methods

// ---- HELPERS ----
const rpc = (method, params = []) => {
  const payload = {
    jsonrpc: "2.0",
    id: 1,
    method,
    params,
  };
  const result = execSync(
    `curl -X POST -s --data '${JSON.stringify(payload)}' http://localhost:8545`
  ).toString();
  return JSON.parse(result);
};

// ---- SCRIPT ----

// Give 1000 ETH
console.log("Giving myself ETH...");
rpc("anvil_setBalance", [
  WALLET,
  "0x3635C9ADC5DEA00000", // 1000 ETH
]);

// Get ape #0 owner
console.log("Fetching owner of Ape #0...");
const owner = execSync(`cast call ${BAYC} "ownerOf(uint256)" 0`)
  .toString()
  .trim();
console.log(`Owner of ape 0 is ${owner}`);

// Impersonate ape #0 owner
console.log("Impersonating Ape #0 owner...");
rpc("anvil_impersonateAccount", [owner]);

// Approve marketplace for all BAYC held by that owner
console.log("🪪 Approving marketplace...");
execSync(
  `cast send ${BAYC} "setApprovalForAll(address,bool)" ${MARKETPLACE} true --from ${owner}`,
  { stdio: "inherit" }
);

// Stop impersonation
console.log(`Stopping impersonation of ${owner}`);
rpc("anvil_stopImpersonatingAccount", [owner]);

console.log("Setup complete!");
console.log("Now funded + impersonating + approved.");
