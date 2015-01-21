//
//  NetUtils.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/14/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit
import Foundation

extension String {
    /**
    A simple extension to the String object to encode it for web request.
    
    :returns: Encoded version of of string it was called as.
    */
    var escaped: String {
        return CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,self,"[].",":/?&=;+!@#$()',*",CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
    }
}

class HTTPPair: NSObject {
    var value: AnyObject
    var key: String!
    
    init(value: AnyObject, key: String?) {
        self.value = value
        self.key = key
    }
    
    func getValue() -> String {
        var val = ""
        if let str = self.value as? String {
            val = str
        } else if self.value.description != nil {
            val = self.value.description
        }
        return val
    }
    
    func stringValue() -> String {
        var val = getValue()
        if self.key == nil {
            return val.escaped
        }
        return "\(self.key.escaped)=\(val.escaped)"
    }
    
}

///the method to serialized all the objects
func serializeObject(object: AnyObject,key: String?) -> Array<HTTPPair> {
    var collect = Array<HTTPPair>()
    if let array = object as? Array<AnyObject> {
        for nestedValue : AnyObject in array {
            collect.extend(serializeObject(nestedValue,"\(key!)[]"))
        }
    } else if let dict = object as? Dictionary<String,AnyObject> {
        for (nestedKey, nestedObject: AnyObject) in dict {
            var newKey = key != nil ? "\(key!)[\(nestedKey)]" : nestedKey
            collect.extend(serializeObject(nestedObject,newKey))
        }
    } else {
        collect.append(HTTPPair(value: object, key: key))
    }
    return collect
}

func stringFromParameters(parameters: Dictionary<String,AnyObject>) -> String {
    return join("&", map(serializeObject(parameters, nil), {(pair) in
        return pair.stringValue()
    }))
}