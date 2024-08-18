//SPDX-License-Identifier: MIT
pragma solidity^0.8.18;

import {Test, console} from "@forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/deployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;

    address User = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external{
       DeployFundMe deployFundMe = new DeployFundMe();
       fundMe = deployFundMe.run();
       vm.deal(User, STARTING_BALANCE);
    } 
    function testMinimumDollaIsFive() public view {
      assertEq(fundMe.MINIMUM_USD(), 5E18);
    }
    function ownerIsMessageSender() public view {
      assertEq(fundMe.getOwner(), msg.sender);
    }
    function testPriceFeedVErsionIsAccurate() public view {
      uint256 version = fundMe.getVersion();
      assertEq(version,4); 
    }
    function testFundFailsWithoutEnoughEth() public{
      vm.expectRevert(); //hey, the next line revert!
      //just like -> assert(this txn fails/reverts)
      fundMe.fund(); // send 0 value 
    }

    function testFundUpdatesFundedDataStructures() public{
      vm.prank(User);
      fundMe.fund{value: SEND_VALUE}();
      uint256 amountFunded = fundMe.getAddressToAmountFunded(address(User));
      assertEq(amountFunded, SEND_VALUE);
    }
    function testAddsFunderToArrayOfFunders() public{
      vm.prank(User);
      fundMe.fund{value: SEND_VALUE}();
      address funder = fundMe.getFunder(0);
      assertEq(funder , User);
    }

    modifier funded(){
      vm.prank(User);
      fundMe.fund{value: SEND_VALUE}();
      _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
      vm.prank(User);
      vm.expectRevert();
      fundMe.withdraw();
    }

    function testWithASingleFunder() public funded {
      //Arrange
      uint256 StartingOwnerBalance = fundMe.getOwner().balance;
      uint256 StartingFundMeBalance = address(fundMe).balance;
      //Act
      vm.prank(fundMe.getOwner());
      fundMe.withdraw();
      //Assert
      uint256 endingOwnerBalance = fundMe.getOwner().balance;
      uint256 endingFundMeBalance = address(fundMe).balance;
      assertEq(endingFundMeBalance, 0);
      assertEq(StartingFundMeBalance + StartingOwnerBalance, endingOwnerBalance);
    }
    function testWithDrawFromMultipleFunders() public funded{
      uint160 numberOfFunders = 10;
      uint160 startingFunderIndex = 2;
      for(uint160 i = startingFunderIndex; i<numberOfFunders; i++){
        //vm.prank new address
        //vm.deal new address
        //address()
        hoax(address(i), SEND_VALUE);
        fundMe.fund{value:SEND_VALUE}();
      }
      uint256 startingOwnerBalance = fundMe.getOwner().balance;
      uint256 startingFundMeBalance = address(fundMe).balance;

      //Act
      vm.startPrank(fundMe.getOwner());
      fundMe.withdraw();
      vm.stopPrank();

      //Assert
      assert(address(fundMe).balance == 0);
      assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
    }
    function testWithDrawFromMultipleFundersCheaper() public funded{
      uint160 numberOfFunders = 10;
      uint160 startingFunderIndex = 2;
      for(uint160 i = startingFunderIndex; i<numberOfFunders; i++){
        //vm.prank new address
        //vm.deal new address
        //address()
        hoax(address(i), SEND_VALUE);
        fundMe.fund{value:SEND_VALUE}();
      }
      uint256 startingOwnerBalance = fundMe.getOwner().balance;
      uint256 startingFundMeBalance = address(fundMe).balance;

      //Act
      vm.startPrank(fundMe.getOwner());
      fundMe.cheaperWithdraw();
      vm.stopPrank();

      //Assert
      assert(address(fundMe).balance == 0);
      assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
    }
}

