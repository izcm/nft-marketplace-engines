/*
forge script MakeHistory.s.sol --sig "month1()"

dev-fork
dev-bootstrap-accounts
dev-deploy-core
dev-bootstrap-nfts
dev-approve

 */

contract MakeHistory is BaseDevScript {
    uint256 internal GENESIS;

    function setUp() internal {
        _loadConfig("deployments.toml", true);
        GENESIS = block.timestamp;
    }

    function month1() external {
        setUp();
        _month1();
    }

    function month2() external {
        setUp();
        _month2();
    }

    function month3() external {
        setUp();
        _month3();
    }

    function finalize() external {
        setUp();
        _jumpToNow();
    }
}
