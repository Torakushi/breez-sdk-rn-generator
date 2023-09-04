import Foundation
import BreezSDK

@objc(RNBreezSDK)
class RNBreezSDK: RCTEventEmitter {
    static let TAG: String = "BreezSDK"
    
    private var breezServices: BlockingBreezServices!
    
    static var breezSdkDirectory: URL {
      let applicationDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
      let breezSdkDirectory = applicationDirectory.appendingPathComponent("breezSdk", isDirectory: true)
      
      if !FileManager.default.fileExists(atPath: breezSdkDirectory.path) {
        try! FileManager.default.createDirectory(atPath: breezSdkDirectory.path, withIntermediateDirectories: true)
      }
      
      return breezSdkDirectory
    }
    
    @objc
    override static func moduleName() -> String! {
        TAG
    }
    
    override func supportedEvents() -> [String]! {
        return [BreezSDKListener.emitterName, BreezSDKLogStream.emitterName]
    }
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    func getBreezServices() throws -> BlockingBreezServices {
        if breezServices != nil {
            return breezServices
        }
        
        throw SdkError.Generic(message: "BreezServices not initialized")
    }

    {% let obj_interface = "" -%}
    {% for func in ci.function_definitions() %}
    {%- if func.name()|ignored_function == false -%}
    {% include "TopLevelFunctionTemplate.swift" %}
    {% endif -%}
    {%- endfor %}  
    @objc(defaultConfig:apiKey:nodeConfig:resolver:rejecter:)
    func defaultConfig(_ envType: String, apiKey: String, nodeConfig: [String: Any], resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        do {
            let nodeConfigData = try BreezSDKMapper.asNodeConfig(nodeConfig: nodeConfigMap)
            var config = try BreezSDK.defaultConfig(envType: BreezSDKMapper.asEnvironmentType(envType: envType), apiKey: apiKey, nodeConfig: nodeConfigData)
            config.workingDir = RNBreezSDK.breezSdkDirectory.path                
            resolve(BreezSDKMapper.dictionaryOf(config: config))
        } catch let err {
            rejectErr(err: err, reject: reject)
        }
    }

    @objc(startLogStream:rejecter:)
    func startLogStream(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        do {
            try BreezSDK.setLogStream(logStream: BreezSDKLogStream(emitter: self))            
            resolve(["status": "ok"])        
        } catch let err {
            rejectErr(err: err, reject: reject)
        }
    }
    
    @objc(connect:seed:resolver:rejecter:)
    func connect(_ config:[String: Any], seed:[UInt8], resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        if self.breezServices != nil {
            reject(RNBreezSDK.TAG, "BreezServices already initialized", nil)
            return
        }
            
        do {
            let config = try BreezSDKMapper.asConfig(config: config)
            self.breezServices = try BreezSDK.connect(config: config, seed: seed, listener: BreezSDKListener(emitter: self))                
            resolve(["status": "ok"])
        } catch let err {
            rejectErr(err: err, reject: reject)
        }
    }
    {%- include "Objects.swift" %}
    func rejectErr(err: Error, reject: @escaping RCTPromiseRejectBlock) {
        var errorCode = "Generic"
        var message = "\(err)"
        if let sdkErr = err as? SdkError {
            if let sdkErrAssociated = Mirror(reflecting: sdkErr).children.first {
                if let associatedMessage = Mirror(reflecting: sdkErrAssociated.value).children.first {
                    message = associatedMessage.value as! String
                }
            }
        }
        reject(errorCode, message, err)
    }
}

{% import "macros.swift" as swift %}
