//
//  ZRTusUploadSpec.swift
//  ZRTusKit
//
//  Created by Zero Cho on 4/16/15.
//  Copyright (c) 2015 Zero. All rights reserved.
//

import Foundation
import XCTest
import ReactKit
import ZRTusKit
import URITemplate
import Mockingjay
import Nimble

class ZRTusUploadSpec : XCTestCase {

  func testUploadAFullFile() {
    stub(http(.HEAD, "http://test/abc"), builder: http(
      status: 200,
      headers: [
        "Offset": "0"
      ]
    ))
    stub(http(.PATCH, "http://test/abc"), builder: http(status: 200))

    let upload = ZRTusUpload(
      url: NSURL(string: "http://test/abc")!,
      fileName: "test.jpg",
      data: "abc".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    )

    let uploadSuccess = self.expectationWithDescription("Upload should be successful")

    upload.upload().onSuccess { result in
      uploadSuccess.fulfill()
    }

    self.waitForExpectationsWithTimeout(2, handler: nil)
  }

  func testPartialUpload() {
    var offset = 5
    var expectedLength = 5
    var expectToReceive = "fghij"

    func httpHeadResponse(request: NSURLRequest) -> Response {
      let resp = NSHTTPURLResponse(
        URL: request.URL!,
        statusCode: 200,
        HTTPVersion: "1.1",
        headerFields: [
          "Offset": toString(offset)
        ]
      )
      return Response.Success(resp!, NSData())
    }
    stub(http(.HEAD, "http://test/abc"), builder: httpHeadResponse)

    func httpPatchResponse(request: NSURLRequest) -> Response {
      let contentLength = toString(request.allHTTPHeaderFields!["Content-Length"]!).toInt()!
      expect(contentLength).to(equal(expectedLength))
      expect(request.HTTPBody!.length).to(equal(expectedLength))
      expect(NSString(data:request.HTTPBody!, encoding: NSUTF8StringEncoding)!).to(equal(expectToReceive))

      let resp = NSHTTPURLResponse(
        URL: request.URL!,
        statusCode: 200,
        HTTPVersion: "1.1",
        headerFields: nil
      )
      return Response.Success(resp!, NSData())
    }
    stub(http(.PATCH, "http://test/abc"), builder: httpPatchResponse)

    let upload = ZRTusUpload(
      url: NSURL(string: "http://test/abc")!,
      fileName: "test.jpg",
      data: "abcdefghij".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    )

    let uploadSuccess = self.expectationWithDescription("Upload should be successful")

    upload.upload().onSuccess { result in
      uploadSuccess.fulfill()
    }

    self.waitForExpectationsWithTimeout(2, handler: nil)
  }

  func testOffsetNotFound() {
    stub(http(.HEAD, "http://test/abc"), builder: http(status: 200))
    stub(http(.PATCH, "http://test/abc"), builder: http(status: 200))

    let upload = ZRTusUpload(
      url: NSURL(string: "http://test/abc")!,
      fileName: "test.jpg",
      data: "abc".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    )

    let uploadFailWithOffsetNotFound = self.expectationWithDescription("Upload should fail with OffsetNotFound")

    upload.upload().onFailure { (e: NSError) in
      if (e.code == ZRTusErrorCode.OffsetNotFound.rawValue) {
        uploadFailWithOffsetNotFound.fulfill()
      }
    }

    self.waitForExpectationsWithTimeout(2, handler: nil)
  }
}