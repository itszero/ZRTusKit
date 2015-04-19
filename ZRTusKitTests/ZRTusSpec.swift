//
//  ZRTusSpec.swift
//  ZRTusKit
//
//  Created by Zero Cho on 4/19/15.
//  Copyright (c) 2015 Zero. All rights reserved.
//

import Foundation
import XCTest
import ZRTusKit
import Mockingjay
import Nimble

class ZRTusSpec : XCTestCase {

  func testUseDefaultHeadersForFailure() {
    stub(uri("http://test/abc"), builder: http(status: 405))

    let tus = ZRTus(url: NSURL(string: "http://test/abc")!)
    let expectation = expectationWithDescription("Use defualt headers")

    tus.serverStatus().onSuccess { (header) in
      expect(header).to(equal(tus.defaultServerStatus))
      expectation.fulfill()
    }
    waitForExpectationsWithTimeout(2, handler: nil)
  }

  func testActualUpload() {
    return
    let tus = ZRTus(url: NSURL(string: "http://localhost:1080/files/")!)
    let uploadFuture = tus.create("1.mp4", data: NSData(contentsOfFile: "/tmp/1.mp4")!, metadata: ["Test": "1"])
    let expectation = expectationWithDescription("Upload successful")

    uploadFuture.onSuccess { (upload) in
      upload.upload().onSuccess { (resp) in
        switch resp {
        case .Success(let statusCode, let serverMessage):
          println("success \(statusCode) \(serverMessage)")
          expectation.fulfill()
        case .Failed(let statusCode, let serverMessage):
          println("failed \(statusCode) \(serverMessage)")
        default:
          println("wat")
        }
      }.onFailure { (error) in println(error) }
    }.onFailure { (error) in println(error) }

    waitForExpectationsWithTimeout(2, handler: nil)
  }

}