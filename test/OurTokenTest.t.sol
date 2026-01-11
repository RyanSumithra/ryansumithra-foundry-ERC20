// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract OurTokenTest is StdCheats, Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant TRANSFER_AMOUNT = 1000 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();
    }

    /*//////////////////////////////////////////////////////////////
                            BASIC TESTS
    //////////////////////////////////////////////////////////////*/

    function testInitialSupplyMintedToDeployer() public {
        assertEq(
            ourToken.balanceOf(msg.sender),
            deployer.INITIAL_SUPPLY()
        );
    }

    function testTotalSupplyMatchesInitialSupply() public {
        assertEq(
            ourToken.totalSupply(),
            deployer.INITIAL_SUPPLY()
        );
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFERS
    //////////////////////////////////////////////////////////////*/

    function testTransferWorks() public {
        ourToken.transfer(alice, TRANSFER_AMOUNT);

        assertEq(ourToken.balanceOf(alice), TRANSFER_AMOUNT);
        assertEq(
            ourToken.balanceOf(msg.sender),
            deployer.INITIAL_SUPPLY() - TRANSFER_AMOUNT
        );
    }

    function testTransferFailsIfInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transfer(bob, 1 ether);
    }

    function testTransferToZeroAddressReverts() public {
        vm.expectRevert();
        ourToken.transfer(address(0), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            ALLOWANCES
    //////////////////////////////////////////////////////////////*/

    function testApproveSetsAllowance() public {
        ourToken.approve(alice, TRANSFER_AMOUNT);

        assertEq(
            ourToken.allowance(msg.sender, alice),
            TRANSFER_AMOUNT
        );
    }

    function testTransferFromWorksWithAllowance() public {
        uint256 initialAllowance = 1000;
        ourToken.approve(alice, initialAllowance);

        uint256 transfer_amount = 500;

        vm.prank(alice);
        ourToken.transferFrom(msg.sender, bob, transfer_amount);

        assertEq(ourToken.balanceOf(bob), transfer_amount);
        assertEq(
            ourToken.balanceOf(msg.sender),
            deployer.INITIAL_SUPPLY() - transfer_amount
        );
    }

    function testTransferFromReducesAllowance() public {
        ourToken.approve(alice, TRANSFER_AMOUNT);

        vm.prank(alice);
        ourToken.transferFrom(msg.sender, bob, TRANSFER_AMOUNT);

        assertEq(
            ourToken.allowance(msg.sender, alice),
            0
        );
    }

    function testTransferFromFailsWithoutAllowance() public {
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(msg.sender, bob, 1 ether);
    }

    function testTransferFromFailsIfAllowanceTooLow() public {
        ourToken.approve(alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(msg.sender, bob, 2 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        SECURITY / INVARIANTS
    //////////////////////////////////////////////////////////////*/

    function testUsersCannotMint() public {
        vm.expectRevert();
        (address(ourToken)).call(
            abi.encodeWithSignature("mint(address,uint256)", address(this), 1)
        );
    }

    function testTotalSupplyNeverChangesAfterTransfers() public {
        ourToken.transfer(alice, TRANSFER_AMOUNT);
        ourToken.transfer(bob, TRANSFER_AMOUNT);

        assertEq(
            ourToken.totalSupply(),
            deployer.INITIAL_SUPPLY()
        );
    }

    /*//////////////////////////////////////////////////////////////
                            EVENTS (OPTIONAL)
    //////////////////////////////////////////////////////////////*/

    function testTransferEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(msg.sender, alice, TRANSFER_AMOUNT);

        ourToken.transfer(alice, TRANSFER_AMOUNT);
    }

    // ERC20 Transfer event declaration
    event Transfer(address indexed from, address indexed to, uint256 value);
}

    // function testAllowancesWorks() public{
    //     uint256 initialAllowance = 1000;

    //     // Bob approves Alice to spend tokens on her behalf
    //     vm.prank(bob);
    //     ourToken.approve(alice, initialAllowance);

    //     uint256 transferAmount = 500;

    //     vm.prank(alice);
    //     ourToken.transferFrom(bob, alice, transferAmount);

    //     assertEq(ourToken.balanceOf(alice), transferAmount);
    //     assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    // }
