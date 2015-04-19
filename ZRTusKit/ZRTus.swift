//
//  ZRTus.swift
//  ZRTusKit
//
//  Created by Zero Cho on 4/17/15.
//  Copyright (c) 2015 Zero. All rights reserved.
//

import Foundation
import BrightFutures

public class ZRTus {

  var url: NSURL
  var cachedServerStatus: [String: String]?
  public let recognizedStatusKeys = [
    "Tus-Resumable",
    "Tus-Version",
    "Tus-Max-Size",
    "Tus-Extension"
  ]
  public let defaultServerStatus: [String: String] = [
    "Tus-Resumable": "1.0.0",
    "Tus-Version": "1.0.0",
    "Tus-Max-Size": "1073741824",
    "Tus-Extension": "creation"
  ]

  public init(url: NSURL) {
    self.url = url
  }

  public func serverStatus() -> Future<[String: String]> {
    if (cachedServerStatus != nil) {
      return future { self.cachedServerStatus! }
    } else {
      let urlRequest = NSMutableURLRequest(URL: self.url)
      urlRequest.HTTPMethod = "OPTIONS"
      return ZRTusUtils.sendRequest(urlRequest).flatMap { (resp: ZRTusUtils.ZRTusHTTPResponse) -> Result<[String: String]> in
        if (resp.httpResponse.statusCode == 200) {
          var newServerStatus = Dictionary<String, String>()
          for key in self.recognizedStatusKeys {
            if let v = resp.httpResponse.allHeaderFields[key] as? String {
              newServerStatus[key] = v
            }
          }
          self.cachedServerStatus = newServerStatus
          return .Success(Box(self.cachedServerStatus!))
        } else {
          println("ZRTus: Remote server does not respond to OPTIONS. Using default status this time.")
          return .Success(Box(self.defaultServerStatus))
        }
      }
    }
  }

  public func checkExtension(serverStatus: [String: String], extensionName: String) -> Bool {
    if let extensions = serverStatus["Tus-Extension"] {
      let extensions = extensions.componentsSeparatedByString(",").map { s in
        s.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
      }
      return contains(extensions, extensionName)
    } else {
      return false
    }
  }

  public func create(fileName: String, data: NSData?, var metadata: [String: String]) -> Future<ZRTusUpload> {
    return self.serverStatus().map { (serverStatus) -> Result<Bool> in
      if !self.checkExtension(serverStatus, extensionName: "creation") {
        return .Failure(NSError(
          domain: "Remote server does not support creation",
          code: ZRTusErrorCode.UnsupportedExtension.rawValue,
          userInfo: nil
        ))
      } else {
        return .Success(Box(true))
      }
    }.flatMap { (b) -> Future<ZRTusUtils.ZRTusHTTPResponse> in
      metadata["filename"] = fileName
      var metadataEncoded = [String]()
      for (k, v) in metadata {
        let data = v.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        metadataEncoded.append("\(k) \(data?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros))")
      }

      let urlRequest = NSMutableURLRequest(URL: self.url)
      urlRequest.HTTPMethod = "POST"
      urlRequest.addValue("0", forHTTPHeaderField: "Content-Length")
      if data != nil {
        urlRequest.addValue("\(data!.length)", forHTTPHeaderField: "Upload-Length")
        urlRequest.addValue("\(data!.length)", forHTTPHeaderField: "Entity-Length") // 0.2.2
        urlRequest.addValue("\(data!.length)", forHTTPHeaderField: "Final-Length")  // 0.2.1
      } else {
        urlRequest.addValue("1", forHTTPHeaderField: "Upload-Defer-Length")
      }
      urlRequest.addValue(", ".join(metadataEncoded), forHTTPHeaderField: "Upload-Metadata")

      return ZRTusUtils.sendRequest(urlRequest)
    }.flatMap { (resp) -> Future<ZRTusUpload> in
      future { () -> Result<ZRTusUpload> in
        if let newLocation = resp.httpResponse.allHeaderFields["Location" as NSString] as? String {
          return .Success(Box(ZRTusUpload(url: NSURL(string: newLocation)!, fileName: fileName, data: data)))
        } else {
          return .Failure(NSError(
            domain: "Expected Location Header in Response",
            code: ZRTusErrorCode.RemoteServerfailure.rawValue,
            userInfo: nil
          ))
        }
      }
    }
  }

}