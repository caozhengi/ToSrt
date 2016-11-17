# ToSrt

![Interface](./src/appInterface.png)

[README](./README.md) | [中文文档](./README_zh.md)

ToSrt是一个可以把ASS和SSA的字幕转换为SRT格式的工具。  
这个过程中会删除原字幕中的特效。  
ToSrt基于 Swift 3.0 开发，最近一次提交基于 MacOS 10.12系统测试。  


## 下载

[Release Page](https://github.com/caozhengi/ToSrt/releases)


## 文件编码

ToSrt会自动检查文件的编码，目前支持UTF-8和GBK编码。
转换的SRT文件编码格式为UTF-8。


## 批量转换
ToSrt支持批量转换，选择多个需要转换的文件即可。



## 对SRT的处理

如果转换的文件原本为SRT格式，那么除了将编码转换为UTF-8将不会做其他处理。


## Bug和需求

如您发现了Bug或有新的需求可以在Issues中提交。  
Bug会优先修复，需求会根据需要的人数和开发难易程序来决定是否开发。

