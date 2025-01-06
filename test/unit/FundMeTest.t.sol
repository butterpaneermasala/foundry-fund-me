// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        DeployFundMe DeployfundMe = new DeployFundMe();
        fundMe = DeployfundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollerIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        // console.log(fundMe.i_owner());
        // console.log(msg.sender);
        assertEq(fundMe.getOwnwer(), msg.sender);
    }

    // What can we do to work with addresses outside our system?
    // 1. Unit
    //      - Testing a sepcific part of out code
    // 2. Integration
    //      - Testing how our code works with other parts of our code
    // 3. Forked
    //      - Testing  our code on simulated real environment
    // 4. Staging
    //      - Tesing our code in a real environment that is not prod

    function testPriceFeedVersionIsAccurate() public view {
        if (block.chainid == 11155111) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            // console.log(version);
            assertEq(version, 6);
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // hey, the next line should revert;

        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next transaction will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 ammountFunded = fundMe.getAddressToAmountFunded(address(USER));
        assertEq(ammountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        vm.prank(USER); // the next transaction will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithOnlyOneFunder() public funded {
        // Arrange
        uint256 startingOwnerBalnace = fundMe.getOwnwer().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwnwer());
        fundMe.withdraw(); // should have spent gas?

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwnwer().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingFundMeBalance + startingOwnerBalnace);
    }

    function testWithDrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunder = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunder; i++) {
            // vm.prank new address
            // vm.deal new address
            // * prank and deal combined -> hoax
            //address(i) -> new address
            hoax(address(i), SEND_VALUE);

            // vm.fund new address
            fundMe.fund{value: SEND_VALUE}();
        }

        // Act
        uint256 startingOwnerBalance = fundMe.getOwnwer().balance;
        uint256 startFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwnwer());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(fundMe.getOwnwer().balance, startFundMeBalance + startingOwnerBalance);
    }

    function testWithDrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunder = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunder; i++) {
            // vm.prank new address
            // vm.deal new address
            // * prank and deal combined -> hoax
            //address(i) -> new address
            hoax(address(i), SEND_VALUE);

            // vm.fund new address
            fundMe.fund{value: SEND_VALUE}();
        }

        // Act
        uint256 startingOwnerBalance = fundMe.getOwnwer().balance;
        uint256 startFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwnwer());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(fundMe.getOwnwer().balance, startFundMeBalance + startingOwnerBalance);
    }
}
