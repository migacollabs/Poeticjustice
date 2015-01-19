// Playground - noun: a place where people can play

import UIKit
import Foundation
import XCPlayground

let SwiftyJSONErrorDomain = "SwiftyJSONErrorDomain"
//MARK:- Base
public enum JSON {
    
    case ScalarNumber(NSNumber)
    case ScalarString(String)
    case Sequence(Array<JSON>)
    case Mapping(Dictionary<String, JSON>)
    case Null(NSError?)
    
    init(data:NSData, options opt: NSJSONReadingOptions = nil, error: NSErrorPointer = nil) {
        if let object: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: opt, error: error){
            self = JSON(object: object)
        } else {
            self = .Null(nil)
        }
    }
    
    init(object: AnyObject) {
        switch object {
        case let number as NSNumber:
            self = .ScalarNumber(number)
        case let string as NSString:
            self = .ScalarString(string)
        case let null as NSNull:
            self = .Null(nil)
        case let array as NSArray:
            var aJSONArray = Array<JSON>()
            for object : AnyObject in array {
                aJSONArray.append(JSON(object: object))
            }
            self = .Sequence(aJSONArray)
        case let dictionary as NSDictionary:
            var aJSONDictionary = Dictionary<String, JSON>()
            for (key : AnyObject, value : AnyObject) in dictionary {
                if let key = key as? NSString {
                    aJSONDictionary[key] = JSON(object: value)
                }
            }
            self = .Mapping(aJSONDictionary)
        default:
            self = .Null(nil)
        }
    }
}

// MARK: - Subscript
extension JSON {
    
    subscript(index: Int) -> JSON {
        get {
            switch self {
            case .Sequence(let array) where array.count > index:
                return array[index]
            default:
                return .Null(NSError(domain: SwiftyJSONErrorDomain, code: 0, userInfo: nil))
            }
        }
    }
    
    subscript(key: String) -> JSON {
        get {
            switch self {
            case .Mapping(let dictionary) where dictionary[key] != nil:
                return dictionary[key]!
            default:
                return .Null(NSError(domain: SwiftyJSONErrorDomain, code: 0, userInfo: nil))
            }
        }
    }
}

//MARK: - Printable, DebugPrintable
extension JSON: Printable, DebugPrintable {
    
    public var description: String {
        switch self {
        case .ScalarNumber(let number):
            return number.description
        case .ScalarString(let string):
            return string
        case .Sequence(let array):
            return array.description
        case .Mapping(let dictionary):
            return dictionary.description
        default:
            return "null"
        }
    }
    
    public var debugDescription: String {
        get {
            switch self {
            case .ScalarNumber(let number):
                return number.debugDescription
            case .ScalarString(let string):
                return string.debugDescription
            case .Sequence(let array):
                return array.debugDescription
            case .Mapping(let dictionary):
                return dictionary.debugDescription
            default:
                return "null"
            }
        }
    }
}

// MARK: - Sequence: Array<JSON>
extension JSON {
    
    var arrayValue: Array<JSON>? {
        get {
            switch self {
            case .Sequence(let array):
                return array
            default:
                return nil
            }
        }
    }
}

// MARK: - Mapping: Dictionary<String, JSON>
extension JSON {
    
    var dictionaryValue: Dictionary<String, JSON>? {
        get {
            switch self {
            case .Mapping(let dictionary):
                return dictionary
            default:
                return nil
            }
        }
    }
}

//MARK: - Scalar: Bool
extension JSON: BooleanType {
    
    public var boolValue: Bool {
        switch self {
        case .ScalarNumber(let number):
            return number.boolValue
        case .ScalarString(let string):
            return (string as NSString).boolValue
        case .Sequence(let array):
            return array.count > 0
        case .Mapping(let dictionary):
            return dictionary.count > 0
        case .Null:
            return false
        default:
            return true
        }
    }
}

//MARK: - Scalar: String, NSNumber, NSURL, Int, ...
extension JSON {
    
    var stringValue: String? {
        get {
            switch self {
            case .ScalarString(let string):
                return string
            case .ScalarNumber(let number):
                return number.stringValue
            default:
                return nil
            }
        }
    }
    
    var numberValue: NSNumber? {
        get {
            switch self {
            case .ScalarString(let string):
                var ret: NSNumber? = nil
                let scanner = NSScanner(string: string)
                if scanner.scanDouble(nil){
                    if (scanner.atEnd) {
                        ret = NSNumber(double:(string as NSString).doubleValue)
                    }
                }
                return ret
            case .ScalarNumber(let number):
                return number
            default:
                return nil
            }
        }
    }
    
    var URLValue: NSURL? {
        get {
            switch self {
            case .ScalarString(let string):
                return NSURL(string: string)
            default:
                return nil
            }
        }
    }
    
    var charValue: Int8? {
        get {
            if let number = self.numberValue {
                return number.charValue
            } else {
                return nil
            }
        }
    }
    
    var unsignedCharValue: UInt8? {
        get{
            if let number = self.numberValue {
                return number.unsignedCharValue
            } else {
                return nil
            }
        }
    }
    
    var shortValue: Int16? {
        get{
            if let number = self.numberValue {
                return number.shortValue
            } else {
                return nil
            }
        }
    }
    
    var unsignedShortValue: UInt16? {
        get{
            if let number = self.numberValue {
                return number.unsignedShortValue
            } else {
                return nil
            }
        }
    }
    
    var longValue: Int? {
        get{
            if let number = self.numberValue {
                return number.longValue
            } else {
                return nil
            }
        }
    }
    
    var unsignedLongValue: UInt? {
        get{
            if let number = self.numberValue {
                return number.unsignedLongValue
            } else {
                return nil
            }
        }
    }
    
    var longLongValue: Int64? {
        get{
            if let number = self.numberValue {
                return number.longLongValue
            } else {
                return nil
            }
        }
    }
    
    var unsignedLongLongValue: UInt64? {
        get{
            if let number = self.numberValue {
                return number.unsignedLongLongValue
            } else {
                return nil
            }
        }
    }
    
    var floatValue: Float? {
        get {
            if let number = self.numberValue {
                return number.floatValue
            } else {
                return nil
            }
        }
    }
    
    var doubleValue: Double? {
        get {
            if let number = self.numberValue {
                return number.doubleValue
            } else {
                return nil
            }
        }
    }
    
    var integerValue: Int? {
        get {
            if let number = self.numberValue {
                return number.integerValue
            } else {
                return nil
            }
        }
    }
    
    var unsignedIntegerValue: Int? {
        get {
            if let number = self.numberValue {
                return number.unsignedIntegerValue
            } else {
                return nil
            }
        }
    }
}

//MARK: - Comparable
extension JSON: Comparable {
    
    private var type: Int {
        get {
            switch self {
            case .ScalarNumber(let number):
                return 1
            case .ScalarString(let string):
                return 2
            case .Sequence(let array):
                return 3
            case .Mapping(let dictionary):
                return 4
            case .Null:
                return 0
            default:
                return -1
            }
        }
    }
}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    
    if lhs.numberValue != nil && rhs.numberValue != nil {
        return lhs.numberValue == rhs.numberValue
    }
    
    if lhs.type != rhs.type {
        return false
    }
    
    switch lhs {
    case JSON.ScalarNumber:
        return lhs.numberValue! == rhs.numberValue!
    case JSON.ScalarString:
        return lhs.stringValue! == rhs.stringValue!
    case .Sequence:
        return lhs.arrayValue! == rhs.arrayValue!
    case .Mapping:
        return lhs.dictionaryValue! == rhs.dictionaryValue!
    case .Null:
        return true
    default:
        return false
    }
}

public func <=(lhs: JSON, rhs: JSON) -> Bool {
    
    if lhs.numberValue != nil && rhs.numberValue != nil {
        return lhs.numberValue <= rhs.numberValue
    }
    
    if lhs.type != rhs.type {
        return false
    }
    
    switch lhs {
    case JSON.ScalarNumber:
        return lhs.numberValue! <= rhs.numberValue!
    case JSON.ScalarString:
        return lhs.stringValue! <= rhs.stringValue!
    case .Sequence:
        return lhs.arrayValue! == rhs.arrayValue!
    case .Mapping:
        return lhs.dictionaryValue! == rhs.dictionaryValue!
    case .Null:
        return true
    default:
        return false
    }
}

public func >=(lhs: JSON, rhs: JSON) -> Bool {
    
    if lhs.numberValue != nil && rhs.numberValue != nil {
        return lhs.numberValue >= rhs.numberValue
    }
    
    if lhs.type != rhs.type {
        return false
    }
    
    switch lhs {
    case JSON.ScalarNumber:
        return lhs.numberValue! >= rhs.numberValue!
    case JSON.ScalarString:
        return lhs.stringValue! >= rhs.stringValue!
    case .Sequence:
        return lhs.arrayValue! == rhs.arrayValue!
    case .Mapping:
        return lhs.dictionaryValue! == rhs.dictionaryValue!
    case .Null:
        return true
    default:
        return false
    }
}

public func >(lhs: JSON, rhs: JSON) -> Bool {
    
    if lhs.numberValue != nil && rhs.numberValue != nil {
        return lhs.numberValue > rhs.numberValue
    }
    
    if lhs.type != rhs.type {
        return false
    }
    
    switch lhs {
    case JSON.ScalarNumber:
        return lhs.numberValue! > rhs.numberValue!
    case JSON.ScalarString:
        return lhs.stringValue! > rhs.stringValue!
    case .Sequence:
        return false
    case .Mapping:
        return false
    case .Null:
        return false
    default:
        return false
    }
}

public func <(lhs: JSON, rhs: JSON) -> Bool {
    
    if lhs.numberValue != nil && rhs.numberValue != nil {
        return lhs.numberValue < rhs.numberValue
    }
    
    if lhs.type != rhs.type {
        return false
    }
    
    switch lhs {
    case JSON.ScalarNumber:
        return lhs.numberValue! < rhs.numberValue!
    case JSON.ScalarString:
        return lhs.stringValue! < rhs.stringValue!
    case .Sequence:
        return false
    case .Mapping:
        return false
    case .Null:
        return false
    default:
        return false
    }
}

// MARK: - NSNumber: Comparable
extension NSNumber: Comparable {
}

public func ==(lhs: NSNumber, rhs: NSNumber) -> Bool {
    return lhs.compare(rhs) == NSComparisonResult.OrderedSame
}

public func <(lhs: NSNumber, rhs: NSNumber) -> Bool {
    return lhs.compare(rhs) == NSComparisonResult.OrderedAscending
}

public func >(lhs: NSNumber, rhs: NSNumber) -> Bool {
    return lhs.compare(rhs) == NSComparisonResult.OrderedDescending
}

public func <=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    return !(lhs > rhs)
}

public func >=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    return !(lhs < rhs)
}

extension String {
    /**
    A simple extension to the String object to encode it for web request.
    
    :returns: Encoded version of of string it was called as.
    */
    var escaped: String {
        return CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,self,"[].",":/?&=;+!@#$()',*",CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
    }
}

/// Creates key/pair of the parameters.
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

func stringFromParameters(parameters: Dictionary<String,AnyObject>) -> String {
    return join("&", map(serializeObject(parameters, nil), {(pair) in
        return pair.stringValue()
    }))
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




//////////////////////////////////////////////////////////////////



var session: NSURLSession
session = NSURLSession.sharedSession()




func get_json_value(json: JSON, key_name: String) -> AnyObject?{
    switch json["results"][0][key_name]{
    case .ScalarString(let stringValue):
        return stringValue
    case .ScalarNumber(let numberValue):
        return numberValue
    default:
        println("ooops!!! JSON Data is Unexpected or Broken")
    }
    return nil
}



func login(params : Dictionary<String, AnyObject>, url : String) {
    
    var request = NSMutableURLRequest(URL: NSURL(string: url)!)
    
    var loginParams = params
    var emailAddress = params["login"] as? String
    
    request.HTTPShouldHandleCookies = true
    request.HTTPMethod = "POST"
    request.HTTPBody = stringFromParameters(params).dataUsingEncoding(NSUTF8StringEncoding)
    
    var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
        if let httpResponse = response as? NSHTTPURLResponse {
            println(httpResponse.statusCode)
            if httpResponse.statusCode == 200 {
                
                if data != nil {
                    
                    var json: JSON? = nil
                    
                    if let jsonResult: NSDictionary =
                        NSJSONSerialization.JSONObjectWithData(
                            data, options: NSJSONReadingOptions.MutableContainers,
                            error: nil) as? NSDictionary{
                                
                        if let results = jsonResult["user"] as? NSDictionary{
                            var device_token:String = results["device_token"] as String
                            if let dt = results["device_token"] as? String{
                                println(dt)
                            }
                                
                        }
                    }
                    
                    if (json != nil){
                        ()
//                        var logged_in = (get_json_value(json!, key_name: "logged_in") as String)
                        
//                        if self.logged_in{
//                            if let handler = self.onLoginHandler{
//                                // call the login handler on the main thread queue
//                                // that seems to be important!
//                                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
//                                dispatch_async(dispatch_get_global_queue(priority, 0), { ()->() in
//                                    dispatch_async(dispatch_get_main_queue(), {
//                                        handler.loggedIn()
//                                    })
//                                })
//                            }
//                        } // end if logged in
                        
                    }
                    
                }
                
            }else{
                print("Error signing in")
                // do something, figure out how to do async error handling
                // without exceptions, because there are no exceptions in
                // swift :(
            }
        }
        
    })
    
    task.resume()
}


var params = Dictionary<String,AnyObject>()

params["login"] = "mat@miga.me"
params["password"] = "Aa12345678"
params["form.submitted"] = true


var login_url = "http://mivid.io:8888/login"

login(params, login_url)




XCPSetExecutionShouldContinueIndefinitely()











