pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
/**
SPDX-License-Identifier: UNLICENSED
**/

contract  lottery { 
    struct History {
        address add;
        string name;
        uint32 prize;
        uint64 timestamp;
        bytes32 hash;
    }
    struct RoundHistory {
        mapping(string=>bool) superiseHistory;
    }
    
    uint32 prizePool;
    uint32 initPool;
    uint32 peopleCount;
    string[] authers;
    uint64 startTime = 1618383755;
    uint64 timeInterval = 300;
    uint round;
    RoundHistory[] roundHistory;
    mapping(address=>string) correspondenceAddr;
    History[][] superiseHistory;
    address bossAddr;
    address creater;
    bool isStart = false;
    string emptyStr = "";
    
    constructor () {
        creater = msg.sender;
    }
    
    function Login(string memory name) public returns(bool hasAuth) {
        hasAuth = false;
        uint autherLength = authers.length;
        for(uint i = 0;i<autherLength;i++){
            if(keccak256(abi.encode(name)) == keccak256(abi.encode(authers[i]))){
                hasAuth = true;
            }
        }
        if (hasAuth){
            correspondenceAddr[msg.sender] = name;
        }
    }
    
    function GetAuth()public view returns(bool boss,bool start){
        boss = bossAddr == msg.sender;
        start = isStart;
    }
    
    function Start(uint32 amount)public {
        require(!isStart,"Already started!");
        require(msg.sender == bossAddr,"must be boss addr");
        require(initPool == 0 ,"Already initialized!");
        require(amount > 8000 ,"amount is too small!");
        initPool =  amount;
        isStart = true;
    }
    
    function AuthVerification()public view returns(bool auth){
        string memory name = correspondenceAddr[msg.sender];
        if (keccak256(abi.encode(name)) == keccak256(abi.encode(emptyStr))){
            return false;
        }
        if (uint64(block.timestamp) < startTime) {
            return false;
        }
        if (!isStart) {
            return false;
        }
        uint roundNow = round;
        if (startTime + uint64(timeInterval * round)  < uint64(block.timestamp)){
            roundNow = round + 1;
        }
        if (round != 0 && roundHistory.length >= roundNow) {
            return !roundHistory[roundNow-1].superiseHistory[name];
        }
        return true;
    }
    
    function GetCountDownTime()public view returns(uint64 timeLeft,uint rounds){
        if (round == 5){
           timeLeft = 0;
           rounds = 5;
        }else{
            uint64 timestamp = uint64(block.timestamp);
            uint64 nextTime =  startTime + uint64(timeInterval * round);
            rounds = round + 1;
            if (nextTime == timestamp){
                timeLeft = 1;
            }else if(nextTime > timestamp){
                timeLeft = nextTime - timestamp;
            }else{
                while(nextTime < timestamp && rounds < 5){
                    nextTime = nextTime + timeInterval;
                    rounds = rounds + 1;
                }
                if (rounds == 5) {
                    timeLeft = 0;
                    rounds = 5;
                }else{
                    timeLeft = nextTime + timeInterval - timestamp;
                }
            }
        }
    }
    
    function GetPrizePool() public view returns(uint32 pool,uint rounds){
        if (startTime + uint64(timeInterval * round)  < uint64(block.timestamp)){
            rounds = round + 1;
            if (round == 5) {
                pool = prizePool + initPool - 8000;
            }else{
                pool = prizePool + 2000;
            }
        }else{
            pool = prizePool;
            rounds = round;  
        }
    }
    
    function GetSuperiseHistory()public view returns(History[][] memory){
        return superiseHistory;
    }
    
    function Superise() public returns(uint32 get,string memory rname,address ruser){
        require(isStart,"lottery not start!");
        while (round < 5 && startTime + uint64(timeInterval * round) < uint64(block.timestamp)){
            startNewRound();
        }
        require(uint64(block.timestamp) > startTime,"new round not start!");
        address user = msg.sender;
        string memory name = correspondenceAddr[user];
        bool isEmpty = keccak256(abi.encode(name)) != keccak256(abi.encode(""));
        require(isEmpty,"Unauthorized address");
        require(prizePool > 0,"prizePool is empty");
        
        if (roundHistory.length >= round) {
            require(!roundHistory[round-1].superiseHistory[name],"User has already drawn a lottery!");
        }
        
        
        
        uint32 random = uint32(uint256(msg.sender) * uint256(block.number) * uint256(block.timestamp));
        
        if (round == 5) {
            uint32 tempPool = prizePool / peopleCount * 2;
            uint32 isLucky = random % 5;
            if (isLucky == 0 && prizePool > 0) {
                get =  random % tempPool;
                prizePool = prizePool - get;
                if (peopleCount == 1){
                    get = get + prizePool;
                    prizePool = 0;
                }
            }else{
                get = 0;
                peopleCount = peopleCount + 1;
            }
        }else{
            uint32 tempPool = prizePool / peopleCount * 3 / 2;
            uint32 distribute = random % 10;
            if (distribute == 0 || distribute == 1) {
                tempPool = tempPool / 10;
            }
            if (distribute == 9){
                tempPool = tempPool * 4;
            }
        
            if (tempPool > prizePool) {
                tempPool = prizePool;
            }
        
            get = random % tempPool;
            if (get == 0) {
                get = 1;
            }
            prizePool = prizePool - get;
            if (prizePool == 0){
                prizePool = peopleCount;
                get = get - peopleCount;
            }
            if (peopleCount == 1){
                get = get + prizePool;
                prizePool = 0;
            }
        }
        
        if (roundHistory.length < round) {
            roundHistory.push();
            superiseHistory.push();
        }
        roundHistory[round-1].superiseHistory[name] = true;
        History storage history = superiseHistory[round-1].push();
        history.add = user;
        history.prize = get;
        history.name = name;
        history.timestamp = uint64(block.timestamp);
        peopleCount = peopleCount -1;
        rname = name;
        ruser = user;
    }
    
    function startNewRound()private{
        round = round + 1;
        if (round == 5) {
            prizePool = prizePool + initPool - 8000;
            peopleCount = 10;
        }else{
            prizePool = prizePool + 2000;
        peopleCount = uint32(authers.length);
        }
    }
    
    function InitAuth (string[] memory auth,address boss,uint64 start)public {
        require(creater == msg.sender,"invaild init!");
        require (authers.length == 0,"authers initialized!");
        require (auth.length > 0,"authers is empty!");
        authers = auth;
        peopleCount = uint32(auth.length);
        bossAddr = boss;
        startTime = start;
    }
}
