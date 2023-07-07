//
//  TimeKit.swift
//  ClosePlayer
//
//  Created by David Reese on 6/18/23.
//

import Foundation

func convertToTimeInterval(from timeString: String) -> TimeInterval? {
    let timeComponents = timeString.components(separatedBy: ":")
    
    // Check if the time string has either 2 or 3 components
    guard timeComponents.count == 2 || timeComponents.count == 3 else {
        return nil
    }
    
    var hours: TimeInterval = 0
    var minutes: TimeInterval = 0
    var seconds: TimeInterval = 0
    
    if timeComponents.count == 3 {
        // Parsing hours, minutes, and seconds
        if let hoursValue = TimeInterval(timeComponents[0]), let minutesValue = TimeInterval(timeComponents[1]), let secondsValue = TimeInterval(timeComponents[2]) {
            hours = hoursValue * 3600
            minutes = minutesValue * 60
            seconds = secondsValue
        } else {
            return nil
        }
    } else {
        // Parsing minutes and seconds only
        if let minutesValue = TimeInterval(timeComponents[0]), let secondsValue = TimeInterval(timeComponents[1]) {
            minutes = minutesValue * 60
            seconds = secondsValue
        } else {
            return nil
        }
    }
    
    let totalTimeInterval = hours + minutes + seconds
    return totalTimeInterval
}
