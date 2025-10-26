// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract LiskGarden {

      enum GrowthStage {
        SEED,      
        SPROUT,    
        GROWING,   
        BLOOMING   
    }

    struct plant {
        uint256 id;
        address owner;
        GrowthStage stage;
        uint256 plantedDate;
        uint256 lastWatered;
        uint8 waterLevel;
        bool exists;
        bool isDead;
    }

    mapping(uint256 => plant) public plants;
    mapping(address => uint256[]) public userPlants;
    address public owner;
    uint256 public plantCounter;
    GrowthStage public currentStage;
    uint8 public constant PLANT_PRICE = 0.001 ether;
    uint8 public constant HARVEST_REWARD = 0.003 ether;
    uint8 public constant STAGE_DURATION = 1 minutes;
    uint8 public constant WATER_DEPLETION_TIME = 30 seconds;
    uint8 public constant WATER_DEPLETION_RATE = 2;
     


    event PlantSeeded(address indexed owner, uint256 indexed plantId);
    event PlantWatered(uint256 indexed plantId, uint8 waterLevel);
    event PlantHarvested(uint256 indexed plantId, uint8 waterLevel);
    event PlantStageAdvanced(uint256 indexed plantId, uint8 waterLevel);
    event PlantDied(uint256 indexed plantId, uint8 waterLevel);

    constructor() {
        owner = msg.sender;
    }



    function plantSeed() external payable returns (uint256) {
        require(msg.value >= PLANT_PRICE);
        plantCounter++;
        plant memory newPlant = plant({
            id: plantCounter,
            owner: msg.sender,
            stage: GrowthStage.SEED,
            plantedDate: block.timestamp,
            lastWatered: block.timestamp,
            waterLevel: 100,
            exists: true,
            isDead: false
        });
        plants[plantCounter] = newPlant;
        userPlants[msg.sender].push(plantCounter);
        emit PlantSeeded(msg.sender, plantCounter);
        return plantCounter;
    }

    function calculateWaterLevel(uint256 plantId) public view returns (uint8) {
        plant memory currentPlant = plants[plantId];
        if (!exists(plantId) || currentPlant.isDead) {
            return 0;
        }
        uint256 timeSinceWatered = block.timestamp - currentPlant.lastWatered;
        uint256 depletionIntervals = timeSinceWatered / WATER_DEPLETION_TIME;
        uint256 waterLost = depletionIntervals * WATER_DEPLETION_RATE;
        if (waterLost >= currentPlant.waterLevel) {
            return 0;
        } else {
            return uint8(currentPlant.waterLevel - waterLost);
        }
    }

    function updateWaterLevel(uint256 plantId) internal {
        uint8 currentWater = calculateWaterLevel(plantId);
        plants[plantId].waterLevel = currentWater;
        if(currentWater == 0 && !plants[plantId].isDead){
            plants[plantId].isDead = true;
            emit PlantDied(plantId, currentWater);
        }
    }

    function waterPlant(uint256 plantId) external {
        require(exists(plantId), "Plant does not exist");
        require(plants[plantId].owner == msg.sender, "Not plant owner");
        require(!plants[plantId].isDead, "Plant is dead");
        plants[plantId].waterLevel = 100;
        plants[plantId].lastWatered = block.timestamp;
        emit PlantWatered(plantId, plants[plantId].waterLevel);
        updatePlantStage(plantId);
    }


    function updatePlantStage(uint256 plantId) public {
        require(exists(plantId), "Plant does not exist");
        updateWaterLevel(plantId);
        if(plants[plantId].isDead) return;
        uint256 timeSincePlanted = block.timestamp - plants[plantId].plantedDate;
        GrowthStage oldStage = plants[plantId].stage;
        if(timeSincePlanted >= 2 * STAGE_DURATION) plants[plantId].stage = GrowthStage.BLOOMING;
        else if(timeSincePlanted >= STAGE_DURATION) plants[plantId].stage = GrowthStage.GROWING;
        else if(timeSincePlanted >= STAGE_DURATION / 2) plants[plantId].stage = GrowthStage.SPROUT;

        if(oldStage != plants[plantId].stage) {
            emit PlantStageAdvanced(plantId, plants[plantId].waterLevel);
        }
    }
 
    function harvestPlant(uint256 plantId) public{
        require(plants[plantId].owner == msg.sender, "Bukan owner");
        require(plants[plantId].exists, "Tidak ada tanaman");
        require(!plants[plantId].isDead, "Tanaman sudah mati");
        require(plants[plantId].stage == GrowthStage.BLOOMING, "Tanaman belum bisa dipanen");
        plants[plantId].exists = false;
        emit PlantHarvested(plantId, plants[plantId].waterLevel);
        (bool success, ) = msg.sender.call{value: HARVEST_REWARD}("");
        require(success, "Transfer failed");
    }


    function getPlant(uint256 plantId) external view returns (plant memory) {
        plant memory currentPlant = plants[plantId];
        currentPlant.waterLevel = calculateWaterLevel(plantId);
        return currentPlant;
    }

    function getUserPlants(address user) external view returns (uint256[] memory) {
        return userPlants[user];
    }

    function exists(uint256 plantId) public view returns (bool) {
        return plants[plantId].exists;
    }

    function withdraw() external {
        require(msg.sender == owner, "Bukan owner");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer gagal");
    }

    receive() external payable {}
}