//
//  ZRTusUtils.swift
//  ZRTusKit
//
//  Created by Zero Cho on 4/18/15.
//  Copyright (c) 2015 Zero. All rights reserved.
//

import Foundation
import BrightFutures

public class ZRTusUtils {

  struct ZRTusHTTPResponse {
    var httpResponse: NSHTTPURLResponse
    var data: NSData
  }

  class ZRTusRequestDelegate : NSObject, NSURLConnectionDataDelegate {
    let progressHandler: ((Int, Int) -> ())?
    let completionHandler: (ZRTusRequestDelegate, NSHTTPURLResponse, NSData) -> ()
    let errorHandler: (ZRTusRequestDelegate, NSError) -> ()
    var response : NSHTTPURLResponse?
    var data : NSMutableData?

    init(
      progressHandler: ((Int, Int) -> ())?,
      completionHandler: (ZRTusRequestDelegate, NSHTTPURLResponse, NSData) -> (),
      errorHandler: (ZRTusRequestDelegate, NSError) -> ()
    ) {
      self.progressHandler = progressHandler
      self.completionHandler = completionHandler
      self.errorHandler = errorHandler
    }

    func connection(connection: NSURLConnection, didSendBodyData bytesWritten: Int, totalBytesWritten: Int, totalBytesExpectedToWrite: Int) {
      if let handler = progressHandler {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
        handler(totalBytesWritten, totalBytesExpectedToWrite)
      }
    }

    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
      if (response.isKindOfClass(NSHTTPURLResponse)) {
        self.response = response as? NSHTTPURLResponse
        self.data = NSMutableData()
      }
    }

    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
      self.data!.appendData(data)
    }

    func connectionDidFinishLoading(connection: NSURLConnection) {
      self.completionHandler(self, response!, data!)
    }

    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
      self.errorHandler(self, error)
    }
  }

  static var delegates : [ZRTusRequestDelegate] = []

  class func sendRequest(request: NSMutableURLRequest, progressHandler: ((Int, Int) -> ())? = nil) -> Future<ZRTusHTTPResponse> {
    let promise = Promise<ZRTusHTTPResponse>()
    var resp: NSURLResponse? = nil
    var error: NSError? = nil
    self.injectHeaders(request)

    func completionHandler(delegate: ZRTusRequestDelegate, resp: NSHTTPURLResponse, data: NSData) {
      removeObject(delegate, fromArray: &delegates)
      let myResponse = ZRTusHTTPResponse(httpResponse: resp, data: data)
      promise.success(myResponse)
    }

    func errorHandler(delegate: ZRTusRequestDelegate, error: NSError) {
      removeObject(delegate, fromArray: &delegates)
      promise.failure(error)
    }

    let delegate = ZRTusRequestDelegate(
      progressHandler: progressHandler,
      completionHandler: completionHandler,
      errorHandler: errorHandler
    )
    delegates.append(delegate)

    let urlConnection = NSURLConnection(
      request: request,
      delegate: delegate,
      startImmediately: true
    )

    return promise.future
  }

  class func injectHeaders(request: NSMutableURLRequest) {
    request.addValue("1.0", forHTTPHeaderField: "Tus-Resumable")
  }
}

private func removeObject<T : Equatable>(object: T, inout fromArray array: [T])
{
  var index = find(array, object)
  array.removeAtIndex(index!)
}