//
//  XCTestCase+Exceptions.swift
//  Muvr
//
//  Created by Jan Machacek on 29/09/2015.
//  Copyright © 2015 Muvr. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    
    func XCTAssertThrows<X : ErrorType where X : Equatable>(exception: X, block: () throws -> Void) {
        do {
            try block()
            XCTFail("Exception was not thrown")
        } catch let x where x is X && (x as! X) == exception {
            // OK
        } catch {
            XCTFail("Bad exception thrown")
        }
    }
    
}