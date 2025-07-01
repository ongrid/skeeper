// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {SKeeper} from "../src/SKeeper.sol";

contract DeploySkeeper is Script {
    SKeeper public skeeper;
    address admin = address(123);
    // The address of the signer EOA, which is used to sign the hash
    // derived from well-known mnemonic phrase at index 0
    // "test test test test test test test test test test test junk"
    address signerEoa = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        skeeper = new SKeeper(admin, signerEoa);

        vm.stopBroadcast();
    }
}
