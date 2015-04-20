//
//  ZRTusUpload.swift
//  ZRTusKit
//
//  Created by Zero Cho on 4/15/15.
//  Copyright (c) 2015 Zero. All rights reserved.
//

import Foundation
import BrightFutures
import ReactKit

public class ZRTusUpload {

  public enum ZRTusUploadResponse {
    case Success(statusCode: Int, serverMessage: String)
    case Failed(statusCode: Int, serverMessage: String)
  }

  var url: NSURL
  var fileName: NSString
  var data: NSData?

  public init(url: NSURL, fileName: NSString, data: NSData?) {
    self.url = url
    self.fileName = fileName
    self.data = data
  }

  public func upload() -> Future<ZRTusUploadResponse> {
    return self.sendHEAD().flatMap { (remoteSize : Int) -> Future<ZRTusUploadResponse> in
      if (self.data!.length < remoteSize) {
        return Future.failed(NSError(domain: "incosistence state: remoteSize > localLength", code: ZRTusErrorCode.InvalidRemoteSize.rawValue, userInfo: nil))
      } else {
        return self.sendPATCH(remoteSize)
      }
    }
  }

  public func sendHEAD() -> Future<Int> {
    let urlRequest = NSMutableURLRequest(URL: self.url)
    urlRequest.HTTPMethod = "HEAD"

    return ZRTusUtils.sendRequest(urlRequest).flatMap { (resp) -> Future<Int> in
      future { () -> Result<Int> in
        let httpResp = resp.httpResponse
        let offsetOpt: AnyObject? = httpResp.allHeaderFields["Offset"]
        switch (offsetOpt) {
          case let value as NSString:
            return .Success(Box(value.integerValue))
          default:
            return .Failure(NSError(domain: "Response header not found: Offset", code: ZRTusErrorCode.OffsetNotFound.rawValue, userInfo: nil))
        }
      }
    }
  }

  public func sendPATCH(offset: Int) -> Future<ZRTusUploadResponse> {
    let urlRequest = NSMutableURLRequest(URL: self.url)
    urlRequest.HTTPMethod = "PATCH"
    urlRequest.addValue("application/offset+octet-stream", forHTTPHeaderField: "Content-Type")
    urlRequest.addValue(toString(self.data!.length - offset), forHTTPHeaderField: "Content-Length")
    urlRequest.addValue(toString(offset), forHTTPHeaderField: "Offset")
    urlRequest.HTTPBody = self.data!.subdataWithRange(NSMakeRange(offset, self.data!.length - offset))

    return ZRTusUtils.sendRequest(urlRequest).map { (resp) -> ZRTusUploadResponse in
      let msg = NSString(data:resp.data, encoding: NSUTF8StringEncoding) as! String

      if (resp.httpResponse.statusCode == 200) {
        return ZRTusUploadResponse.Success(statusCode: 200, serverMessage: msg)
      } else {
        return ZRTusUploadResponse.Failed(statusCode: resp.httpResponse.statusCode, serverMessage: msg)
      }
    }
  }
}