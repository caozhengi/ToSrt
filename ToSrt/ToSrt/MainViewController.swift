//
//  MainViewController.swift
//  ToSrt
//
//  Created by Cao Zheng on 2016/11/14.
//  Copyright © 2016年 Cao Zheng. All rights reserved.
//

import Cocoa
import Foundation

class MainViewController: NSViewController, NSOpenSavePanelDelegate {
    
    // 按钮和文字等UI控件
    @IBOutlet weak var fileSourceLabel: NSTextField!
    @IBOutlet weak var fileTargetLabel: NSTextField!
    @IBOutlet weak var fileSourceButton: NSButton!
    @IBOutlet weak var fileTargetButton: NSButton!
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    // 文件选择面板
    var selectFilePanel = NSOpenPanel();
    // 保存文件目录面板
    var targetFilePanel = NSOpenPanel();
    // 选择的文件路径
    var selectedFiles:[URL] = [];
    // 转换后的目标路径
    var targetPath:URL?;
    // 转换的进度，已经转换的文件
    var progressNumber = 0;
    // 格式字符串
    var formatStr:String?;
    // 未处理的字幕字符串组成数组
    var dialogueArr:[String] = [];
    // Format信息中时间轴开始的字段位置
    var startIndex = 0;
    // Format信息中时间轴结束的字段位置
    var endIndex = 0;
    // Format信息中字幕文本的位置
    var textIndex = 0;

    override func viewDidLoad() {
        super.viewDidLoad()
        // 设置文件选择框和代理
        self.selectFilePanel.delegate = self;
        self.selectFilePanel.canChooseFiles = true;
        self.selectFilePanel.canChooseDirectories = false;
        self.selectFilePanel.allowsMultipleSelection = true;
        self.selectFilePanel.allowedFileTypes = ["ass","ssa","srt"];
        // 设置保存文件目录面板和代理
        self.targetFilePanel.delegate = self;
        self.targetFilePanel.canChooseFiles = false;
        self.targetFilePanel.canChooseDirectories = true;
        self.targetFilePanel.allowsMultipleSelection = false;
        
    }

    // 点击选择文件的按钮
    @IBAction func fileSourceClick(_ sender: NSButton) {
        self.selectFilePanel.runModal()
    }
    
    // 点击目录文件的按钮
    @IBAction func fileTargetClick(_ sender: NSButton) {
        self.targetFilePanel.runModal()
    }

    // 点击开始按钮
    @IBAction func startBottonClick(_ sender: Any) {
        // 没有选择文件时提示用户
        if self.selectedFiles.count == 0 {
            self.messageLabel.stringValue = "Please select the file to be converted!"
            return
        }
        //没有选择目标文件夹时提示用户
        if self.targetPath == nil {
            self.messageLabel.stringValue = "Select the destination folder!"
            return
        }
        
        // 初始化转换状态
        self.messageLabel.stringValue = "Start the conversion file, please wait!"
        self.progressBar.doubleValue = 0.0
        self.startButton.isEnabled = false;

        // 创建队列
        let queue = DispatchQueue(label: "processAssFile", target: nil)

        // 开始转换
        for url in self.selectedFiles {
            queue.async {
                //转换文件
                self.processAssFile(url);
                self.progressNumber += 1;
                // 主线程中刷新UI
                DispatchQueue.main.async {
                    //处理进度条
                    self.progressBar.doubleValue = Double(self.progressNumber) / Double(self.selectedFiles.count) * 100.0
                    //处理文字
                    if self.progressNumber < self.selectedFiles.count {
                        self.messageLabel.stringValue = "\(url.lastPathComponent) conversion is complete!"
                    }else{
                        self.progressNumber = 0
                        self.messageLabel.stringValue = "Complete!"
                        self.startButton.isEnabled = true;
                    }
                }
            
            }
        }
    }

    // 当用户选择文件时执行的方法
    func panel(_ sender: Any, validate url: URL) throws {
        let panel = sender as! NSOpenPanel;
        
        if panel === self.selectFilePanel {
            self.selectedFiles = panel.urls;
            if panel.urls.count > 1 {
                self.fileSourceLabel.stringValue = panel.urls[0].deletingLastPathComponent().path
            } else {
                self.fileSourceLabel.stringValue = panel.urls[0].lastPathComponent
            }
        }
        
        if panel === self.targetFilePanel {
            self.targetPath = panel.urls[0];
            self.fileTargetLabel.stringValue = panel.urls[0].path;
        }

    }
    
    func changeMessage(_ str: String) {
        self.messageLabel.stringValue = str
    }
    
    // 处理单个ASS和SSA文件
    func processAssFile(_ url: URL) {
        // 读取的文件内容
        let fileStr = self.loadFile(url);
        // 文件的扩展名
        let fileExt = url.pathExtension.lowercased();
        // 新的需要保存的文件名
        let fileName = url.deletingPathExtension().appendingPathExtension("srt").lastPathComponent
        // 保存文件的路径
        let filePath = (self.targetPath?.path)! + "/" + fileName;

        // 根据不同扩展名以不同的方式处理文件
        switch fileExt {
        case "ass","ssa":
            if let eventStr = self.extractEventStr(fileStr){
                self.formatStr = self.extractFormatStr(eventStr)
                self.dialogueArr = self.extractDialogueStr(eventStr)
                self.getInfoIndex()
                self.dialogueArr = self.sortByStartTime(self.dialogueArr)
                //转换并保存文件
                let fileContent = self.convertToSrt(self.dialogueArr)
                self.saveSrtFile(fileContent: fileContent, filePath: filePath)
            }
            break
        case "srt":
            self.saveSrtFile(fileContent: fileStr, filePath: filePath)
            break
        default:
            self.messageLabel.stringValue = "Unsupported format!"
        }
    }

    // 根据UTF和GBK格式来读取文件
    func loadFile(_ url: URL) -> String {
        var str = "";

        do {
            try str = String.init(contentsOf: url)
        } catch {
            do {
                let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue));
                try str = NSString(contentsOf: url, encoding: enc) as String;
            } catch {
                print("不支持您的编码");
            }
        }
        return str;
    }
    
    // 提取字幕中[Events]事件后的字符串
    func extractEventStr(_ str: String) -> String? {
        //定义正则表达式
        let pattern = "\\[Events\\](.|\\n)*";
        let regular = try! NSRegularExpression(pattern: pattern, options:.dotMatchesLineSeparators)
        let result = regular.firstMatch(in: str, options: .reportProgress , range: NSMakeRange(0, str.unicodeScalars.count))
        //截取结果
        if let eventStr = result {
            return (str as NSString).substring(with: eventStr.range)
        }
        return nil
    }

    // 提取Format格式字符串
    func extractFormatStr(_ str: String) -> String? {
        //定义正则表达式
        let pattern = "Format.*";
        let regular = try! NSRegularExpression(pattern: pattern, options:.caseInsensitive)
        let result = regular.firstMatch(in: str, options: .reportProgress , range: NSMakeRange(0, str.unicodeScalars.count))
        //截取结果
        if let formatStr = result {
            return (str as NSString).substring(with: formatStr.range)
        }
        return nil
    }
    
    // 提取Dialogue字幕字符串
    func extractDialogueStr(_ str: String) -> Array<String> {
        var dialogueArr:[String] = [];
        //定义正则表达式
        let pattern = "Dialogue.*";
        let regular = try! NSRegularExpression(pattern: pattern, options:.caseInsensitive)
        let results = regular.matches(in: str, options: .reportProgress , range: NSMakeRange(0, str.unicodeScalars.count))
        //截取结果
        for result in results {
            dialogueArr.append((str as NSString).substring(with: result.range))
        }
        return dialogueArr;
    }
    
    // 根据Format信息来获取Start, End, Text三个字段的位置
    func getInfoIndex(){
        if let formatStr = self.formatStr {
            let arr = formatStr.components(separatedBy: ",")
            for (index,value) in arr.enumerated() {
                let str = value.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                if str == "Start" {
                    self.startIndex = index
                };
                if str == "End" {
                    self.endIndex = index
                };
                if str == "Text" {
                    self.textIndex = index
                };
            }
        }
    }
    
    // 对字幕数组内的数据按照时间轴的开始时间进行排序
    func sortByStartTime(_ arr:Array<String>) -> Array<String> {
        var results:[String] = [];
        
        results = arr.sorted(by: { (a, b) -> Bool in
            weak var weakSelf = self;
            let aStart = a.components(separatedBy: ",")[weakSelf!.startIndex]
            let bStrat = b.components(separatedBy: ",")[weakSelf!.startIndex]
            return aStart < bStrat
        })
        return results;
    }
    
    // 把字幕转换为SRT格式
    func convertToSrt(_ arr:Array<String>) -> String {
        var srtStr = "";
        for (index, value) in arr.enumerated() {
            // 截取时间和文字的字符串
            let arr = value.components(separatedBy: ",")
            var startTime = arr[self.startIndex];
            var endTime = arr[self.endIndex];
            var text = arr.dropFirst(self.textIndex).joined(separator: ",")
            // 对时间字符串进行处理
            startTime = startTime.replacingOccurrences(of: ".", with: ",").appending("0")
            endTime = endTime.replacingOccurrences(of: ".", with: ",").appending("0")
            // 对文字字符串处理，删除特效
            let pattern = "\\{.*?\\}";
            let regular = try! NSRegularExpression(pattern: pattern, options:.caseInsensitive)
            let results = regular.matches(in: text, options: .reportProgress , range: NSMakeRange(0, text.unicodeScalars.count))
            var tmpArr:[String] = [];
            for result in results {
                tmpArr.append((text as NSString).substring(with: result.range))
            }
            for value in tmpArr {
                text = text.replacingOccurrences(of: value, with: "")
            }
            // 替换空格和换行
            text = text.replacingOccurrences(of: "\\N", with: "\n")
            text = text.replacingOccurrences(of: "\\h", with: " ")
            // 拼接所有srt字幕的字符串
            srtStr += "\(index + 1)\n\(startTime) --> \(endTime)\n\(text)\n\n";
        }
        return srtStr;
    }
    
    // 输出文件
    func saveSrtFile(fileContent:String, filePath:String){
        try! fileContent.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8);
    }
}
