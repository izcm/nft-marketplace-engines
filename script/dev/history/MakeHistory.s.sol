// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/*
forge script MakeHistory.s.sol --sig "week1()"

dev-fork
dev-bootstrap-accounts
dev-deploy-core
dev-bootstrap-nfts
dev-approve
dev-make-history week1()
dev-make-history week2()
dev-make-history week3()
dev-make-history week4()
dev-make-history finalize()
*/

/*
1. start.sh creates fork ~30 days back
   and writes:
     - HISTORY_START_TS
     - NOW_TS
   to .env
2. the above scripts execute
3. week1() fills days [0–7]
4. week2() fills days [7–14]
5. week3() fills days [14–21]
6. week4() fills days [21–30]
7. finalize() jumps block.timestamp to exactly NOW_TS
*/

import {Config} from "forge-std/Config.sol";
import {console} from "forge-std/console.sol";

// local
import {BaseDevScript} from "dev/BaseDevScript.s.sol";

contract MakeHistory is BaseDevScript, Config {
    uint256 internal HISTORY_START_TS;

    function setUp() internal {
        _loadConfig("deployments.toml", true);
        HISTORY_START_TS = vm.envUint("HISTORY_START_TS");
    }

    function week1() external {
        setUp();
        _jumpToWeek(0);
        _week1();
    }

    function week2() external {
        setUp();
        _jumpToWeek(1);
        // _week2();
    }

    function week3() external {
        setUp();
        _jumpToWeek(2);
        // _week3();
    }

    function week4() external {
        setUp();
        _jumpToWeek(3);
        // _week4();
    }

    function finalize() external {
        setUp();
        _jumpToNow();
    }

    function _week1() internal {}

    // --------------------------------
    // INTERNAL TIME HELPERS
    // --------------------------------

    function _jumpToWeek(uint256 weekIndex) internal {
        // weekIndex = 0,1,2,3
        vm.warp(HISTORY_START_TS + (weekIndex * 7 days));
    }

    function _jumpToNow() internal {
        vm.warp(vm.envUint("NOW_TS"));
    }
}
