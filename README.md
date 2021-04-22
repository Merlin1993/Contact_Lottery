# Contact_Lottery
抽奖合约

# 随机算法
每个人的奖池 为 总奖池除以剩余人数，乘以1.5倍。

随机数 = 账户 * 区块号 * 区块时间戳。

随机数 对 10 取余 ，如果为0或1，则奖池缩小10倍；如果为10，则奖池增大4倍。

随机数 对 奖池取余 ， 得到的值即为中奖金额。

备注：为了避免某个人中大奖后，后面的人抽不到钱，所以会保留剩余人数*2的奖金。每个人最低能中1元。

# API
InitAuth  设置抽奖基本参数

入参|解释
---|:--:
auth|可以抽奖者的名单
boss|启动抽奖账号
start|启动时间
interval|抽奖间隔时间
roundPool|每轮奖池
lastRoundCount|最后一轮人数
---

Login 抽奖者登录，不登录无法进行抽奖

入参|解释
---|:--:
name|抽奖者姓名

出参|解释
---|:--:
hasAuth|是否有权限加入抽奖
---

GetAuth 获取当前账户是否可以启动，是否已经启动

出参|解释
---|:--:
boss|当前账户是否可以启动
start|是否已经启动
---

AuthVerification 获取当前账户本轮是否可以抽奖

出参|解释
---|:--:
auth|本轮是否可以抽奖
end | 是否已经第五轮完成抽奖
---

GetCountDownTime 获取下轮开启剩余时间

出参|解释
---|:--:
timeLeft|下轮剩余时间
rounds|下一轮的轮次
---

GetPrizePool() 获取奖池金额

出参|解释
---|:--:
pool|当前轮奖池数
rounds|当前为第几轮
---

GetSurpriseHistory 获取抽奖记录

出参|解释
---|:--:
History|中奖记录
---

Surprise 开始本轮抽奖

出参|解释
---|:--:
get|中奖金额
rname|中奖者姓名
ruser|中奖者账户地址
round|当前轮次
---
