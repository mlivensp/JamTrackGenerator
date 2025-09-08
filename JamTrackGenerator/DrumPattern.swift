////
////  DrumPattern.swift
////  JamTrackGenerator
////
////  Created by Michael Livenspargar on 8/27/25.
////
//
//import Foundation
//
//
//struct DrumPattern {
//    let definition: Definition
////    static let pattern05: Pattern = Pattern(chorus: pattern05Chorus())
//    
//    init(definition: Definition) {
//        self.definition = definition
//    }
////    
////    var pattern05: Pattern {
////        Pattern(chorus: pattern05Chorus(definition: definition))
////    }
//    
//    func pattern05Chorus(definition: Definition) -> [DrumDescriptor] {
//        var events: [DrumDescriptor] = []
//        var pulseAtMeasureStart: UInt32 = 0
//        var counter = 0
//        // bars 1-4
//        events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//        events.append(.init(part: .crashCymbal1, on: pulseAtMeasureStart, off: pulseAtMeasureStart + NoteDuration.whole.value))
//        pulseAtMeasureStart += NoteDuration.whole.value
//        
//        repeat {
//            events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//            pulseAtMeasureStart += NoteDuration.whole.value
//            counter += 1
//        } while counter < 3
//        
//        // bars 5-6
//        events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//        events.append(.init(part: .crashCymbal1, on: pulseAtMeasureStart, off: pulseAtMeasureStart + NoteDuration.whole.value))
//        pulseAtMeasureStart += NoteDuration.whole.value
//        events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//        pulseAtMeasureStart += NoteDuration.whole.value
//        
//        
//        // bars 7-8
//        events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//        events.append(.init(part: .crashCymbal1, on: pulseAtMeasureStart, off: pulseAtMeasureStart + NoteDuration.whole.value))
//        pulseAtMeasureStart += NoteDuration.whole.value
//        events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//        pulseAtMeasureStart += NoteDuration.whole.value
//        
//        // bars 9-10
//        events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//        events.append(.init(part: .crashCymbal1, on: pulseAtMeasureStart, off: pulseAtMeasureStart + NoteDuration.whole.value))
//        pulseAtMeasureStart += NoteDuration.whole.value
//        events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//        pulseAtMeasureStart += NoteDuration.whole.value
//        
//        // bars 11-12
//        events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//        events.append(.init(part: .crashCymbal1, on: pulseAtMeasureStart, off: pulseAtMeasureStart + NoteDuration.whole.value))
//        pulseAtMeasureStart += NoteDuration.whole.value
//        events.append(contentsOf: createPattern0Measure(definition: definition, pulseAtMeasureStart: pulseAtMeasureStart))
//        pulseAtMeasureStart += NoteDuration.whole.value
//        
//        return events
//    }
//    
//    fileprivate func createPattern0Measure(definition: Definition, pulseAtMeasureStart: UInt32) -> [DrumDescriptor] {
//        let firstEighth: NoteDuration
//        let secondEighth: NoteDuration
//        
//        if definition.feel?.name == "Straight" {
//            firstEighth = NoteDuration.eighth
//            secondEighth = NoteDuration.eighth
//        } else {
//            firstEighth = NoteDuration.eighthTripletSwing
//            secondEighth = NoteDuration.eighthTriplet
//        }
//        
//        var events: [DrumDescriptor] = []
//        var currentPulse = pulseAtMeasureStart
//        var counter = 0
//        repeat {
//            events.append(.init(part: .acousticBassDrum, on: currentPulse, off: currentPulse + NoteDuration.quarter.value))
//            currentPulse += NoteDuration.quarter.value
//            events.append(.init(part: .acousticBassDrum, on: currentPulse, off: currentPulse + NoteDuration.quarter.value))
//            events.append(.init(part: .acousticSnare, on: currentPulse, off: currentPulse + NoteDuration.quarter.value))
//            currentPulse += NoteDuration.quarter.value
//            counter += 1
//        } while counter < 2
//        
//        counter = 0
//        currentPulse = pulseAtMeasureStart
//        repeat {
//            var offPulse = currentPulse + firstEighth.value
//            events.append(.init(part: .closedHiHat, on: currentPulse, off: offPulse))
//            currentPulse = offPulse
//            offPulse = currentPulse + secondEighth.value
//            events.append(.init(part: .closedHiHat, on: currentPulse, off: offPulse))
//            currentPulse = offPulse
//            counter += 1
//        } while counter < 4
//        
//        return events
//    }
//}
