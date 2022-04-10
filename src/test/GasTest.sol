// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";

import "../ERC721AX.sol";
import {MockERC721A} from "./MockERC721A.sol";
import {MockERC721AX} from "./MockERC721AX.sol";

contract GasTest is DSTestPlus {
    Vm vm = Vm(HEVM_ADDRESS);

    address alice = address(0x101);
    address bob = address(0x102);
    address chris = address(0x103);
    address tester = address(this);

    MockERC721A erc721a;
    MockERC721AX erc721ax;

    function setUp() public {
        erc721a = new MockERC721A("Token", "TKN", 1, 30, 10);
        erc721ax = new MockERC721AX("Token", "TKN", 1, 30, 10);

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(chris, "Chris");

        vm.label(tester, "TestContract");
        vm.label(address(erc721a), "ERC721A");
        vm.label(address(erc721ax), "ERC721AX");

        erc721a.mint(tester, 5);
        erc721ax.mint(tester, 5);

        vm.startPrank(alice);
        erc721a.setApprovalForAll(tester, true);
        erc721ax.setApprovalForAll(tester, true);
        vm.stopPrank();

        vm.startPrank(bob);
        erc721a.setApprovalForAll(tester, true);
        erc721ax.setApprovalForAll(tester, true);
        vm.stopPrank();

        vm.startPrank(chris);
        erc721a.setApprovalForAll(tester, true);
        erc721ax.setApprovalForAll(tester, true);
        vm.stopPrank();
    }

    /* ------------- mint() ------------- */

    function test_mint1_ERC721A() public {
        erc721a.mint(alice, 1);
    }

    function test_mint1_ERC721AX() public {
        erc721ax.mint(alice, 1);
    }

    function test_mint5_ERC721A() public {
        erc721a.mint(alice, 5);
    }

    function test_mint5_ERC721AX() public {
        erc721ax.mint(alice, 5);
    }

    /* ------------- transfer() ------------- */

    function test_transferFrom1_ERC721A() public {
        erc721a.transferFrom(tester, bob, 1);
    }

    function test_transferFrom1_ERC721AX() public {
        erc721ax.transferFrom(tester, bob, 1);
    }

    function test_transferFrom5_ERC721A() public {
        erc721a.transferFrom(tester, bob, 1);
        erc721a.transferFrom(bob, alice, 1);
        erc721a.transferFrom(alice, chris, 1);
        erc721a.transferFrom(chris, bob, 1);
        erc721a.transferFrom(bob, alice, 1);
    }

    function test_transferFrom5_ERC721AX() public {
        erc721ax.transferFrom(tester, bob, 1);
        erc721ax.transferFrom(bob, alice, 1);
        erc721ax.transferFrom(alice, chris, 1);
        erc721ax.transferFrom(chris, bob, 1);
        erc721ax.transferFrom(bob, alice, 1);
    }
}
