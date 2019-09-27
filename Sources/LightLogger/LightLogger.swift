import os
import Foundation

// MARK: -
enum LLogEnvironmentVar: String {
    case forceLogging = "LLOG_FORCE_LOGGING"

    var exists: Bool {
        return ProcessInfo.processInfo.environment[rawValue] != nil
    }
}

enum LogLevel: Int, Comparable {

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    case none = 0
    case error
    case warning
    case success
    case info
    case timer
    case appEvent
    case custom
}

// Symbol support
extension LogLevel {
    var symbol: String {
        switch self {
        case .none:     return ""
        case .error:    return "⛔️"
        case .warning:  return "⚠️"
        case .success:  return "✅"
        case .info:     return "📬"
        case .timer:    return "⏲"
        case .appEvent: return "📱"
        case .custom:   return "✏️"
        }
    }
}

// os_log support for newer systems
@available(iOS 10.0, *)
extension LogLevel {
    var logType: OSLogType {
        switch self {
        case .info:             return OSLogType.info
        case .error, .warning:  return OSLogType.error
        case .none, .success, .timer, .appEvent, .custom: return OSLogType.default
        }
    }
}

/*----------------------------------------------------------------------------*/

class LightLogger {
    static var verbosityLevel: LogLevel = .custom
    static var iconsEnabled = true
}

func LLog(_ error: Error?) {
    guard let error = error else { return }
    LLog(error)
}

func LLog(_ error: Error, file: NSString = #file, line: UInt = #line, isPublic: Bool = false) {
    LLog((error as NSError).localizedDescription, level: .error, isPublic: isPublic, file: file, line: line)
}

func LLog(condition: @autoclosure () -> Bool, message: String) {
    assert(condition(), message)
}

func LLog(_ message: String, level: LogLevel = .info, isPublic: Bool = false, includesCallerInfo: Bool = true, subsystem: String = "com.lightlogger.system", category: String = "general", file: NSString = #file, line: UInt = #line) {

    let forcedLogging = LLogEnvironmentVar.forceLogging.exists

    #if DEBUG
    // Pass
    #else
    // Nothing to log in Production (unless it is set on the environment or it is a public one)
    if !(isPublic || forcedLogging) {
        return
    }
    #endif

    guard level <= LightLogger.verbosityLevel else { return }

    let symbol       = LightLogger.iconsEnabled ? level.symbol : ""
    let callerInfo   = includesCallerInfo ? "[\(file.lastPathComponent):\(line)]" : ""

    let logStatement = "\(callerInfo) \(symbol) \(message)"

    if #available(iOS 10.0, *) {
        let oslog = OSLog(subsystem: subsystem, category: category)
        os_log("%@", log: oslog, type: level.logType, logStatement)
    } else {
        print(logStatement)
    }

}

