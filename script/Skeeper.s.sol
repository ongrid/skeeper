// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {SKeeper} from "../src/SKeeper.sol";

contract DeploySkeeper is Script {
    SKeeper public skeeper;
    address admin = address(123);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        skeeper = new SKeeper(admin);

        vm.stopBroadcast();
    }
}
