////
////  SongSection.swift
////  JamTrackGenerator
////
////  Created by Michael Livenspargar on 9/1/25.
////
//
//import Foundation
//
//enum SongSection: CaseIterable, Identifiable  {
//    var id: Self { self }
//    
//    case intro
//    case verse
//    case chorus
//    case bridge
//    case outro
//    case end
//}
//
//extension SongSection: CustomStringConvertible{
//    var description: String {
//        switch self {
//        case .intro:
//            return "Intro"
//        case .verse:
//            return "Verse"
//        case .chorus:
//            return "Chorus"
//        case .bridge:
//            return "Bridge"
//        case .outro:
//            return "Outro"
//        case .end:
//            return "End"
//        }
//    }
//}
//
//extension SongSection {
//    var sortOrder: Int {
//        switch self {
//        case .intro:
//            return 0
//        case .verse:
//            return 1
//        case .chorus:
//            return 2
//        case .bridge:
//            return 3
//        case .outro:
//            return 4
//        case .end:
//            return 5
//        }
//    }
//}
