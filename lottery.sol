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
    }
    struct RoundHistory {
        mapping(string=>bool) surpriseHistory;
    }
    
    uint32 sInitPool;
    string[] sAuthers;
    uint64 sStartTime = 1618383755;
    uint64 sTimeInterval = 300;
    address sBossAddr;
    address sCreater;
    string sEmptyStr = "";
    uint32 sRoundPool = 2000;
    uint32 sLastRoundCountRate = 5;
    
    uint32 mLastRoundCount = 10;
    uint32 mPrizePool;
    uint32 mPeopleCount;
    uint mRound;
    RoundHistory[] mRoundHistory;
    mapping(address=>string) mCorrespondenceAddr;
    History[][] mSurpriseHistory;
    bool mIsStart = false;
    
    constructor () {
        sCreater = msg.sender;
    }
    
    function Login(string memory name) public returns(bool hasAuth) {
        hasAuth = false;
        uint autherLength = sAuthers.length;
        for(uint i = 0;i<autherLength;i++){
            if(keccak256(abi.encode(name)) == keccak256(abi.encode(sAuthers[i]))){
                hasAuth = true;
                break;
            }
        }
        if (hasAuth){
            mCorrespondenceAddr[msg.sender] = name;
        }
    }
    
    function GetAuth()public view returns(bool boss,bool start){
        boss = sBossAddr == msg.sender;
        start = mIsStart;
    }
    
    function Start(uint32 amount)public {
        require(!mIsStart,"Already started!");
        require(msg.sender == sBossAddr,"must be boss addr");
        require(sInitPool == 0 ,"Already initialized!");
        require(amount > sRoundPool * 4 ,"amount is too small!");
        sInitPool =  amount;
        mIsStart = true;
    }
    
    function AuthVerification()public view returns(bool auth){
        string memory name = mCorrespondenceAddr[msg.sender];
        if (keccak256(abi.encode(name)) == keccak256(abi.encode(sEmptyStr))){
            return false;
        }
        if (uint64(block.timestamp) < sStartTime) {
            return false;
        }
        if (!mIsStart) {
            return false;
        }
        uint roundNow = mRound;
        if (sStartTime + uint64(sTimeInterval * mRound)  < uint64(block.timestamp)){
            roundNow = mRound + 1;
        }
        if (mRound != 0 && mRoundHistory.length >= roundNow) {
            return !mRoundHistory[roundNow-1].surpriseHistory[name];
        }
        return true;
    }
    
    function GetCountDownTime()public view returns(uint64 timeLeft,uint rounds){
        uint64 timestamp = uint64(block.timestamp);
        if(timestamp < sStartTime){
            rounds = 1;
            timeLeft = sStartTime - timestamp;
            return (timeLeft,rounds);
        }
        rounds = (timestamp - sStartTime) / sTimeInterval + 2;
        if (rounds > 5){
             rounds = 5;
             timeLeft = 0;
        }else{
            timeLeft = sTimeInterval - (timestamp - sStartTime) % sTimeInterval;
        }
    }
    
    function GetPrizePool() public view returns(uint32 pool,uint rounds){
        if (sStartTime + uint64(sTimeInterval * mRound)  < uint64(block.timestamp) && mRound < 5){
            rounds = mRound + 1;
            if (rounds == 5) {
                pool = mPrizePool + sInitPool - sRoundPool * 4;
            }else{
                pool = mPrizePool + sRoundPool;
            }
        }else{
            pool = mPrizePool;
            rounds = mRound;  
        }
    }
    
    function GetSuperiseHistory()public view returns(History[][] memory){
        return mSurpriseHistory;
    }
    
    function Surprise() public returns(uint32 get,string memory rname,address ruser){
        require(mIsStart,"lottery not start!");
        while (mRound < 5 && sStartTime + uint64(sTimeInterval * mRound) < uint64(block.timestamp)){
            startNewRound();
        }
        require(uint64(block.timestamp) > sStartTime,"new round not start!");
        address user = msg.sender;
        string memory name = mCorrespondenceAddr[user];
        bool isNotEmpty = keccak256(abi.encode(name)) != keccak256(abi.encode(sEmptyStr));
        require(isNotEmpty,"Unauthorized address");
        require(mPrizePool > 0,"prizePool is empty");
        
        if (mRoundHistory.length >= mRound) {
            require(!mRoundHistory[mRound-1].surpriseHistory[name],"User has already drawn a lottery!");
        }
        
        uint32 random = uint32(uint256(msg.sender) * uint256(block.number) * uint256(block.timestamp));
        
        if (mRound == 5) {
            uint32 tempPool = mPrizePool / mLastRoundCount * 2;
            uint32 isLucky = random % 5;
            if ((isLucky == 0 || mPeopleCount == mLastRoundCount) && mPrizePool > 0) {
                get =  random % tempPool;
                mPrizePool = mPrizePool - get;
                mLastRoundCount = mLastRoundCount - 1;
            }else{
                get = 0;
            }
            mPeopleCount = mPeopleCount -1;
            if (mPeopleCount == 0){
                get = get + mPrizePool;
                mPrizePool = 0;
            }
        }else{
            uint32 tempPool = mPrizePool / mPeopleCount * 3 / 2;
            uint32 distribute = random % 10;
            if (distribute == 0 || distribute == 1) {
                tempPool = tempPool / 10;
            }
            if (distribute == 9){
                tempPool = tempPool * 4;
            }
        
            if (tempPool > mPrizePool) {
                tempPool = mPrizePool;
            }
        
            get = random % tempPool;
            if (get == 0) {
                get = 2;
            }
            mPrizePool = mPrizePool - get;
            mPeopleCount = mPeopleCount -1;
            if (mPrizePool < mPeopleCount * 2){
                mPrizePool = mPeopleCount * 2;
                get = get - mPeopleCount * 2;
            }
            if (mPeopleCount == 0){
                get = get + mPrizePool;
                mPrizePool = 0;
            }
        }
        
        if (mRoundHistory.length < mRound) {
            mRoundHistory.push();
            mSurpriseHistory.push();
        }
        mRoundHistory[mRound-1].surpriseHistory[name] = true;
        History storage history = mSurpriseHistory[mRound-1].push();
        history.add = user;
        history.prize = get;
        history.name = name;
        history.timestamp = uint64(block.timestamp);
        rname = name;
        ruser = user;
    }
    
    function startNewRound()private{
        mRound = mRound + 1;
        if (mRound == 5) {
            mPrizePool = mPrizePool + sInitPool - sRoundPool * 4;
        }else{
            mPrizePool = mPrizePool + sRoundPool;
        }
        mPeopleCount = uint32(sAuthers.length);
    }
    
    function InitAuth (string[] memory auth,address boss,uint64 start,uint64 interval,uint32 roundPool,uint32 lastRoundCount)public {
        require(sCreater == msg.sender,"invaild init!");
        require (sAuthers.length == 0,"authers initialized!");
        require (interval > 10,"interval too small!");
        require (auth.length > 0,"authers is empty!");
        require (roundPool > 0,"roundPool is empty!");
        require (lastRoundCount > 0,"roundPool is empty!");
        sAuthers = auth;
        mPeopleCount = uint32(auth.length);
        mLastRoundCount = lastRoundCount;
        sBossAddr = boss;
        sStartTime = start;
        sTimeInterval = interval;
        sRoundPool = roundPool;
        sLastRoundCountRate = mPeopleCount / mLastRoundCount;
    }
}
