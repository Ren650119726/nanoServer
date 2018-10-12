# nanoserver(客户端仅用于调试)

### 功能介绍

1. 首次运行自动创建MySQL数据库表结构
2. 结构化日志
3. 血战三人玩法/四人玩法完整实现
4. 微信登录/支付
5. 游客测试登录
6. 热更补丁下载(Web服务器模块)
7. 保存游戏记录,  回放支持
8. 房间整体流程(玩家开房/俱乐部开房/玩家邀请/解散房间)
9. 支持WebSocket(https://github.com/lonnng/nanoserver/blob/2018aaf60b55e182f466c733dce14d95c7533e74/cmd/mahjong/game/game.go#L83)
10. ... ...

## `Nano`文档

- English
    + [How to build your first nano application](https://github.com/lonnng/nano/blob/master/docs/get_started.md)
    + [Route compression](https://github.com/lonnng/nano/blob/master/docs/route_compression.md)
    + [Communication protocol](https://github.com/lonnng/nano/blob/master/docs/communication_protocol.md)
    + [Design patterns](https://github.com/lonnng/nano/blob/master/docs/design_patterns.md)
    + [API Reference(Server)](https://godoc.org/github.com/lonnng/nano)

- 简体中文
    + [如何构建你的第一个nano应用](https://github.com/lonnng/nano/blob/master/docs/get_started_zh_CN.md)
    + [路由压缩](https://github.com/lonnng/nano/blob/master/docs/route_compression_zh_CN.md)
    + [通信协议](https://github.com/lonnng/nano/blob/master/docs/communication_protocol_zh_CN.md)
    + [API参考(服务器)](https://godoc.org/github.com/lonnng/nano)

## 源码编译

```bash
go get github.com/lonnng/nano
go get github.com/lonnng/nanoserver
cd $GOPATH/src/github.com/lonnng/nanoserver/cmd/mahjong
go build
./mahjong
```

## 配置

- 数据库配置
- 语音账号配置(如果有客户端)
- 微信登录和支付配置
- 端口配置

## LICENSE
MIT LICENSE
