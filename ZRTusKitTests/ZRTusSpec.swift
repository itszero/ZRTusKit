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

}