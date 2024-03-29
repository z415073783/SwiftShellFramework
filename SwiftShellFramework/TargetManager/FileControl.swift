//
//  FileControl.swift
//  writePlist
//
//  Created by zlm on 2018/8/17.
//  Copyright © 2018年 zlm. All rights reserved.
//

import Foundation
public struct ProjectPathModel {
    public var name: String = ""
    public var path: String = ""
    public func fullPath() -> String {
        return path + "/" + name
    }
}
public extension String {
    //根据文件全路径获取文件所在路径
    public func getPath() -> String? {
        guard let newPath = self.regularExpressionReplace(pattern: "/[^/]*?$", with: "") else {
            MMLOG.error("正则表达式未能匹配该路径 plistPath = \(self)")
            return nil
        }
        return newPath
    }
}
public class FileControl {
    
    /// 通过根节点查找每个子节点下的指定文件位置
    ///
    /// - Parameters:
    ///   - rootPath: 根目录
    ///   - selectFile: 文件名称
    ///   - isSuffix: 是否是后缀,如果为true,则搜索后缀为selectFile变量的文件
    ///   - onlyOne: 是否查询到第一个就返回
    ///   - 向下递归次数: 99为无限向下递归, 0为不递归
    /// - Returns: <#return value description#>
    public class func getFilePath(rootPath: String, selectFile: String, isSuffix: Bool = false, onlyOne: Bool = true, recursiveNum: Int = 99) -> [ProjectPathModel] {
        var _rootPath = rootPath
        if _rootPath.count == 0 {
            _rootPath = "./"
        }
        var pathList: [ProjectPathModel] = []
        do {
            let list = try FileManager.default.contentsOfDirectory(atPath: _rootPath)
            var subDirList: [String] = []
            for item in list {
                var changeRootPath = _rootPath
                if changeRootPath == "./" {
                    changeRootPath = "."
                }
                if !changeRootPath.hasSuffix("/") {
                    changeRootPath = changeRootPath + "/"
                }
                let newPath = changeRootPath + item
                var isDir: ObjCBool = false
                let isExist = FileManager.default.fileExists(atPath: newPath, isDirectory: &isDir)
//                MMLOG.info("newPath = \(newPath), isDir = \(isDir) isExist = \(isExist) isSuffix = \(isSuffix)")
                if isSuffix == true {
                    if item.hasSuffix(selectFile) {
                        //找到后缀相同的文件
                        MMLOG.info("获取到后缀相同的文件路径: \(newPath)")
                        pathList.append(ProjectPathModel(name: item, path: changeRootPath))
                    }
                }
//                 && isDir.boolValue == false
                if item == selectFile {
                    //获取到同名文件
                    MMLOG.info("获取到文件路径: \(newPath)")
                    pathList.append(ProjectPathModel(name: item, path: changeRootPath))
                } else if isDir.boolValue == true && isExist == true {
                    //当前目录是文件夹,则存入文件夹数组,以便进行递归遍历
                    subDirList.append(newPath)
                }
                if onlyOne == true, pathList.count == 1 {
                    return pathList
                }
            }

            let newRecursiveNum = recursiveNum >= 99 ? recursiveNum : recursiveNum - 1
            if newRecursiveNum < 0 {
                return pathList
            }
            for subDir in subDirList {
                let subList = getFilePath(rootPath: subDir, selectFile: selectFile, isSuffix: isSuffix, onlyOne: onlyOne, recursiveNum: newRecursiveNum)
                if subList.count > 0 {
                    pathList += subList
                    if onlyOne == true {
                        return pathList
                    }
                }
            }

        } catch {
            MMLOG.error("传入的根路径不存在: rootPath = \(rootPath)")
        }
        return pathList
    }
    
    /// 从当前路径向上查找指定文件
    ///
    /// - Parameter beginPath: beginPath description
    /// - Returns: return value description
    public class func findFile(beginPath: String, goalFileName: String) -> ProjectPathModel? {
        do {
            let list = try FileManager.default.contentsOfDirectory(atPath: beginPath)
            for item in list {
                if item == goalFileName {
                    MMLOG.info("已找到文件! newPath = \(beginPath)")
                    return ProjectPathModel(name: item, path: beginPath)
                }
            }
            //去掉最后一个/路径
            guard let newPath = beginPath.regularExpressionReplace(pattern: "/[^/]*?$", with: "") else {
                MMLOG.error("正则表达式未能匹配该路径 beginPath = \(beginPath)")
                return nil
            }
            return findFile(beginPath: newPath, goalFileName: goalFileName)
        } catch {
            MMLOG.error("error = \(error)")
            return nil
        }
        
        
    }
    
    
    /// 查找指定后缀格式的文件路径 从plist文件开始往上层查找
    ///
    /// - Parameters:
    ///   - plistPath: property.plist文件路径
    ///   - findFileSuffix: 文件后缀
    /// - Returns:
    public class func getProjectPath(plistPath: String, findFileSuffix: String = ".xcworkspace") ->ProjectPathModel? {
        MMLOG.info("plistPath = \(plistPath)")
        guard let newPath = plistPath.regularExpressionReplace(pattern: "/[^/]*?$", with: "") else {
            MMLOG.error("正则表达式未能匹配该路径 plistPath = \(plistPath)")
            return nil
        }
        do {
            let list = try FileManager.default.contentsOfDirectory(atPath: newPath)
            for item in list {
                if item.hasSuffix(findFileSuffix) {
                    MMLOG.info("已找到工程路径! newPath = \(newPath)")
                    return ProjectPathModel(name: item, path: newPath)
                }
            }
            return getProjectPath(plistPath: newPath)
        } catch {
            MMLOG.error("error = \(error)")
            return nil
        }
    }
    
    /// 判断文件是否存在
    public class func isExist(atPath filePath : String) -> Bool {
        return FileManager.default.fileExists(atPath: filePath)
    }
    /// 创建文件目录
    @discardableResult public class func creatDir(atPath dirPath : String) -> Bool {
        MMLOG.info("检查文件目录是否存在: \(dirPath)")
        if isExist(atPath: dirPath) { return false }
        do {
            MMLOG.info("创建文件目录: \(dirPath)")
            try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            MMLOG.info("文件目录创建成功")
            return true
        } catch {
            MMLOG.info("文件目录创建失败 error = \(error)")
            return false
        }
    }
    
    
    /// 从源工程目录下某个关键文件夹 下查找并替换目标工程对应的所有文件
    ///
    /// - Parameters:
    ///   - projectPath: 源目录 注意 源目录不能 带有git
    ///   - targetProjectPath: 目标目录
    /// - Returns:
    public class func searcPathAndmoveToTargetPath(projectPath: String,targetProjectPath:String)-> Bool {
        
        let dic = FileManager.default.enumerator(atPath: projectPath)
        
        while let obj = dic?.nextObject() as? String {
            MMLOG.info("obj = \(obj)")
            ///只替换Resource 目录下 非.DS_Stor 隐藏问题 其中
            if !obj.contains(".DS_Store") && !obj.contains(".git") {
                var isDir:ObjCBool = false
                let sourcePath = projectPath + "/" + obj
                let result = FileManager.default.fileExists(atPath: sourcePath, isDirectory: &isDir)
                if result == true {
                    if isDir.boolValue == true {
                        // 路径 不管
                        MMLOG.info("路径 obj = \(obj)")
                    } else  {
                        // 文件替换
                        MMLOG.info("文件 obj = \(obj)")
                        if let fileName = obj.split("/").last {
                            let result = FileControl.findAndReplaceFile(sourceFilePath: sourcePath, sourceFilName: fileName, targetReplacePath: targetProjectPath)
                            if result ==  false {
                                MMLOG.info("文件\(obj)替换失败")
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    
    public class func readMarkDownFile(filePath: String)-> String {
        let isExist = FileManager.default.fileExists(atPath: filePath)
        if isExist {
            do {
                let url =  URL(fileURLWithPath: filePath)
                
                let docFnfo = try String.init(contentsOf: url, encoding: String.Encoding.utf8)
                MMLOG.info("文件 obj = \(docFnfo)")

                return docFnfo
//                let array = docFnfo.split("\r\n")
//
//                for text  in array {
//                    MMLOG.info(text)
//                }

                
                
                //                let docFnfo = try String.init(contentsOf: URL.init(string: filePath)!, encoding: String.Encoding.utf8)
//                MMLOG.info("文件 obj = \(docFnfo)")

            }
            catch {
                
            }
            
        }
        return ""
    }

    
    
    /// 从根路径查找指定文件并替换新文件
    ///
    /// - Parameters:
    ///   - sourceFilePath: 源文件完整路径 需要替换的资源路径
    ///   - sourceFilName: 源文件名 需要替换的资源名称
    ///   - targetReplacePath: 需要替换的目标路径(可为根路径)
    ///   - isCopy: 是否为copy 如果为false 则进行剪切操作
    /// - Returns:
    public class func findAndReplaceFile(sourceFilePath:String, sourceFilName:String, targetReplacePath:String, isCopy: Bool = true) -> Bool{
        MMLOG.info("资源文件路径:\(sourceFilePath), 资源文件名称:\(sourceFilName), 需要替换对的目标文件:\(targetReplacePath)")
        let searchResult = FileControl.getFilePath(rootPath: targetReplacePath, selectFile: sourceFilName, isSuffix: false, onlyOne: true)
        if let searchResult = searchResult.first {
            MMLOG.info(searchResult.name)
            MMLOG.info(searchResult.fullPath())
            do {
                if FileManager.default.fileExists(atPath: sourceFilePath) {
                    try FileManager.default.removeItem(atPath: searchResult.fullPath())
                    if isCopy {
                        try FileManager.default.copyItem(atPath: sourceFilePath, toPath: searchResult.fullPath())
                    } else {
                        try FileManager.default.moveItem(atPath: sourceFilePath, toPath: searchResult.fullPath())
                    }
                } else {
                    MMLOG.error("源文件不存在,无法替换")
                    return false
                }
            }
            catch {
                MMLOG.error("替换目标文件 sourceFilName = \(sourceFilName), targetReplacePath=\(searchResult.fullPath()) 错误error = \(error) ")
                return false
            }
        } else {
            MMLOG.error("未搜索到指定文件")
            return false
        }
        return true
    }
    
    
    
}
