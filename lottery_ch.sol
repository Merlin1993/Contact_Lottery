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
        require(!mIsStart,"抽奖已经开始");
        require(msg.sender == sBossAddr,"该账户无权启动抽奖");
        require(sInitPool == 0 ,"奖池金额不能为0!");
        require(amount > sRoundPool * 4 ,"奖池金额必须超过前四轮抽奖总金额!");
        sInitPool =  amount;
        mIsStart = true;
    }
    
    function AuthVerification()public view returns(bool auth,bool end){
        string memory name = mCorrespondenceAddr[msg.sender];
        if (keccak256(abi.encode(name)) == keccak256(abi.encode(sEmptyStr))){
            return (false,false);
        }
        if (uint64(block.timestamp) < sStartTime) {
            return (false,false);
        }
        if (!mIsStart) {
            return (false,false);
        }
        uint roundNow = mRound;
        while (sStartTime + uint64(sTimeInterval * mRound)  < uint64(block.timestamp) && roundNow < 5){
            roundNow = roundNow + 1;
        }
        if (mRound != 0 && mRoundHistory.length >= roundNow) {
            bool isDrawn = mRoundHistory[roundNow-1].surpriseHistory[name];
            if (isDrawn && roundNow == 5) {
                return (false,true);
            }else{
                return (!isDrawn,false);
            }
        }
        return (true,false);
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
        uint64 timestamp = uint64(block.timestamp);
        if(timestamp <= sStartTime){
            pool = sRoundPool;
            rounds =1 ;
            return (pool,rounds);
            
        }
        if (sStartTime + uint64(sTimeInterval * mRound)  < timestamp && mRound < 5){
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
    
    function GetSurpriseHistory()public view returns(History[][] memory){
        return mSurpriseHistory;
    }
    
    function Surprise() public returns(uint32 get,string memory rname,address ruser,uint round){
        require(mIsStart,"抽奖未开始，请等待开始!");
        while (mRound < 5 && sStartTime + uint64(sTimeInterval * mRound) < uint64(block.timestamp)){
            startNewRound();
        }
        require(mPeopleCount > 0,"抽奖还未初始化!");
        require(uint64(block.timestamp) > sStartTime,"抽奖还未开始，请稍等!");
        address user = msg.sender;
        string memory name = mCorrespondenceAddr[user];
        bool isNotEmpty = keccak256(abi.encode(name)) != keccak256(abi.encode(sEmptyStr));
        require(isNotEmpty,"账号未授权抽奖！！");
        require(mPrizePool > 0,"奖池已清空!");
        
        if (mRoundHistory.length >= mRound) {
            require(!mRoundHistory[mRound-1].surpriseHistory[name],"用户已经抽过奖，请把机会留给其他人。");
        }
        
        uint32 random = uint32(uint256(msg.sender) * uint256(block.number) * uint256(block.timestamp));
        
        if (mRound == 5) {
            uint32 isLucky = random % sLastRoundCountRate;
            if ((isLucky == 0 || mPeopleCount == mLastRoundCount) && mPrizePool > 0) {
                uint32 tempPool = mPrizePool * 2 / mLastRoundCount;
                if (tempPool > mPrizePool) {
                    tempPool = mPrizePool;
                }
                get =  random % tempPool;
                mPrizePool = mPrizePool - get;
                mLastRoundCount = mLastRoundCount - 1;
            }else{
                get = 0;
            }
            mPeopleCount = mPeopleCount -1;
            if (mPeopleCount == 0 || mLastRoundCount == 0){
                get = get + mPrizePool;
                mPrizePool = 0;
            }
        }else{
            uint32 tempPool = mPrizePool * 3 / 2 / mPeopleCount;
            uint32 distribute = random % 10;
            if (distribute == 0 || distribute == 1) {
                tempPool = tempPool / 10;
                if (tempPool == 0){
                    tempPool = 1;
                }
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
        
        while (mRoundHistory.length < mRound) {
            mRoundHistory.push();
            mSurpriseHistory.push();
        }
        mRoundHistory[mRound-1].surpriseHistory[name] = true;
        History storage history = mSurpriseHistory[mRound-1].push();
        history.add = user;
        history.prize = get;
        history.name = name;
        history.timestamp = uint64(block.timestamp);
        round = mRound;
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
        require(sCreater == msg.sender,"初始化账户不合法!");
        require (sAuthers.length == 0,"用户已经初始化!");
        require (start > sStartTime,"启动时间过早，请重新设定!");
        require (interval < 864000,"间隔时间过长，请重新设定!");
        require (interval > 10,"间隔时间过短，请重新设定!");
        require (auth.length > 0,"授权用户数有误，请确认!");
        require (roundPool > 0,"每轮中奖金额不得为0!");
        require (lastRoundCount > 0,"最后一轮中奖人数不得为0!");
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
