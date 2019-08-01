//
//  MMJSON.swift
//  CallServerSDK
//
//  Created by zlm on 2018/7/17.
//
/*
 使用范例:
 声明model: 申明方式和HandyJSON一致,但是继承的类要改为MMJSONCodable
 // MARK: - 👉 获取自己的ID
class UserDataMyIDModel: NSObject {
    // 获取自己的ID
    static let interfaceName = "getMyId"

    struct Input: MMJSONCodable {
    }

    struct Output: MMJSONCodable {
        var id: String = ""
    }
 }

 */


import Foundation
public typealias MMJSONCodable = Codable
public enum MMJSONResultType: String, MMJSONCodable {
    case fail = "resultType::FAIL",
    success = "resultType::SUCCESS"
}

public struct MMJSONResult: MMJSONCodable {
    public var errorCode: Int = 0
    public var errorDesc: String = ""
    public var operateID: String = ""
    public var type: MMJSONResultType = .fail
    public init() {
    }
}
struct MMJSONBaseOutputModel<T: MMJSONCodable>: MMJSONCodable {
    var result: MMJSONResult?
    var body: T?
}
struct MMJSONBaseModel<T: Codable>: MMJSONCodable {
    var method: String = ""
    var param: T?
}

@objc public class MMJSONRpcManager: NSObject {
    @objc public static let shared = MMJSONRpcManager()

    @objc public var call: ((_ info: String?) -> String)?
    //配置数据源
    @objc public class func setCall(block: ((_ info: String?) -> String)?) {
        shared.call = block
    }
}

public class MMJSON {

    /// 基础方法
    ///
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - input: <#input description#>
    ///   - bodyClass: <#bodyClass description#>
    ///   - block: <#block description#>
    public class func getDataSync <R: MMJSONCodable, T: MMJSONCodable> (name: String, input: R?, bodyClass: T.Type,
                                                     block: @escaping (_ model: T?, _ result: MMJSONResult?) -> Void) {
        do {
            let encoder = JSONEncoder()
            let inputData = try encoder.encode(MMJSONBaseModel(method: name, param: input))
            let inputStr = String(data: inputData, encoding: String.Encoding.utf8)

            guard let rpcBlock = MMJSONRpcManager.shared.call else {
                MMLOG.error("未设置Rpc数据获取方法")
                return
            }
#if DEBUG
            MMLOG.info("DEBUG rpc Data: Input = \(String(describing: inputStr))")
#endif
            let result = rpcBlock(inputStr)
#if DEBUG
            MMLOG.info("DEBUG rpc Data: Output = \(String(describing: result))")
#endif
            let decoder = JSONDecoder()
            let output = try decoder.decode(MMJSONBaseOutputModel<T>.self, from: result.data(using: String.Encoding.utf8)!)

            if let outputResult = output.result {
                block(output.body, outputResult)
                if outputResult.type == .fail {
                    MMLOG.error("RPC接口请求失败! outputResult = \(outputResult) \n inputStr = \(inputStr)")
                }
            } else {
                var result = MMJSONResult()
                result.type = .success
                block(output.body, result)
            }
        } catch {
            let err = """
            name = \(name)
======================================================================
json数据解析失败,请检查以下原因:
1.参数类型是否一致?
2.是否有缺少参数?
3.是否有多的参数? 如果有多的参数但是并不是Rpc需要的参数,请改为可选类型(?)
======================================================================
"""
            print("error = \(error) \n\(err)")
            assert(false, "error = \(error)")
            block(nil, MMJSONResult())
        }
    }
}

extension String {
    /// 字符串转model
    ///
    /// - Parameter DataClass: model对象
    /// - Returns: 返回实例
    func getJSONDataSync<T: MMJSONCodable> (_ DataClass: T.Type) ->T? {
        do {
            let decoder = JSONDecoder()
            let output = try decoder.decode(DataClass, from: self.data(using: String.Encoding.utf8) ?? Data())
            return output
        } catch {
            print("字符串转换错误: OutputClass = \(DataClass)\n value = \(self)")
            return nil
        }
    }

}


