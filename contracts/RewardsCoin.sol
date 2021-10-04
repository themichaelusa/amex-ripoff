//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

struct ComboData {
    uint resetInterval;
    uint lastComboTime;
    uint currentCombo;
    uint totalVolumeInInterval;
}

// point of this coin is to stack up combos

contract RewardsCoin is ERC20 {

    // mapping for keeping track of last spent time for coin
    mapping (address => ComboData) public userComboData;
    address private _governer;
    address[] private userList;
    uint private userCount;
    //address _pointSource;
    
    // combo starts at 
    uint public comboMultiplier;
    uint public comboCeiling;

    uint public lotteryAmount;
    uint public lotteryInterval;
    uint public lotteryLastChecked;
    uint256 lotteryNonce;

    // maps address => struct(uint: last time, uint: current combo)
    // empty struct

    constructor(uint256 initialSupply, address governer) ERC20("ComboCoin", "CC"){
        _mint(msg.sender, initialSupply);
        _governer = governer;
        registerUser(governer);

        // TODO: turn these into 
        comboMultiplier = 2;
        comboCeiling = 10;
        lotteryAmount = 0;
        lotteryInterval = 300;
        lotteryLastChecked = block.timestamp;  
    }

    // utility functions
    function random(uint upperLimit) private returns (uint) {
        lotteryNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, lotteryNonce))) % upperLimit;
    }

    function registerUser(address user) public {
        userComboData[user] = ComboData({
            resetInterval: 86400, 
            lastComboTime: block.timestamp, 
            currentCombo: 0,
            totalVolumeInInterval: 0
        });

        userList.push(user);
        userCount++;
    }

    function claimLottery() public returns (bool) {
        if ((block.timestamp - lotteryLastChecked) > lotteryInterval){
            address winner = userList[random(userCount-1)];
            _transfer(address(this), winner, lotteryAmount);
            lotteryAmount = 0;
            return true;
        }
        return false;
    }

    // built-in functions
    function _validRecipient(address to) private view returns (bool) {
        return userComboData[to].resetInterval > 0;
    }

    function mintRewards(address to, uint spend) public returns (bool) {
        // only the governer can mint rewards + governer cannot mint rewards for itself
        if (msg.sender != _governer || to == _governer){
            return false;
        }

        bool mintSucessful = false;
        uint diff = block.timestamp - userComboData[to].lastComboTime;
        if (diff < userComboData[to].resetInterval){

            // if combo not at ceiling, and within range...
            if (userComboData[to].currentCombo != comboCeiling){
                userComboData[to].currentCombo *= comboMultiplier;
            }

            userComboData[to].totalVolumeInInterval += spend;
        }
        else {
            // if outside of bounds, mint rewards to user
            uint oldCombo = userComboData[to].currentCombo;
            uint rewards = (oldCombo * userComboData[to].totalVolumeInInterval)/100;
            _mint(to, rewards);

            // lottery setup
            _mint(address(this), rewards/100); //lottery amount...
            lotteryAmount += rewards/100;

            // if outside of bounds, reset relevant vars
            userComboData[to].currentCombo = 0;
            userComboData[to].totalVolumeInInterval = 0;
            userComboData[to].lastComboTime = block.timestamp;
            mintSucessful = true;
        }

        return mintSucessful;
    }

    // hooks
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(_validRecipient(to), "ERC20WithSafeTransfer: invalid recipient");
    }

    // transfer func 
    // if spent within certain interval, boost rewards... 

    // how to give intrinsic value to coin??
    // build lottery function... 

    // check burn interval

    // if a user doesn't swap their coin within a specific burn interval...
    // then burn their coin next time they try to use it
    // by sending it back to the contact

    // contract will proportion some reserve
}

/*
contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}
*/


