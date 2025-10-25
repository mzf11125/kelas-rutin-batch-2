// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract LearnString {
    // Variabel string untuk menyimpan nama tanaman
    string public plantName;
    uint256 public waterLevel;
    bool public isAlive;
    address public owner;
    uint256 public plantedtime;

    // Constructor mengatur nilai awal
    constructor() {
        plantName = "Rose";
        waterLevel = 100;
        isAlive = true;
        owner = msg.sender;  
        plantedtime = block.timestamp;
    }

    function Water() public {
        waterLevel = 100;
    }

    function changeStatus(bool _status) public {
        isAlive = _status;
    }

    function getAge( ) public view returns(uint256)  {
        return block.timestamp - plantedtime;
    } 
}