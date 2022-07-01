//
// Copyright © 2022 osy. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import Virtualization

/// Device settings.
@available(iOS, unavailable, message: "Apple Virtualization not available on iOS")
@available(macOS 11, *)
struct UTMAppleConfigurationDevices: Codable {
    enum PointerDevice: String, Codable {
        case disabled = "Disabled"
        case mouse = "Mouse"
        case trackpad = "Trackpad"
    }
    
    var hasAudio: Bool = true
    
    var hasBalloon: Bool = true
    
    var hasEntropy: Bool = true
    
    var hasKeyboard: Bool = true
    
    var pointer: PointerDevice = .mouse
    
    enum CodingKeys: String, CodingKey {
        case hasAudio = "Audio"
        case hasBalloon = "Balloon"
        case hasEntropy = "Entropy"
        case hasKeyboard = "Keyboard"
        case pointer = "Pointer"
    }
    
    init() {
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        hasAudio = try values.decode(Bool.self, forKey: .hasAudio)
        hasBalloon = try values.decode(Bool.self, forKey: .hasBalloon)
        hasEntropy = try values.decode(Bool.self, forKey: .hasEntropy)
        hasKeyboard = try values.decode(Bool.self, forKey: .hasKeyboard)
        pointer = try values.decode(PointerDevice.self, forKey: .pointer)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasAudio, forKey: .hasAudio)
        try container.encode(hasBalloon, forKey: .hasBalloon)
        try container.encode(hasEntropy, forKey: .hasEntropy)
        try container.encode(hasKeyboard, forKey: .hasKeyboard)
        try container.encode(pointer, forKey: .pointer)
    }
}

// MARK: - Conversion of old config format

@available(iOS, unavailable, message: "Apple Virtualization not available on iOS")
@available(macOS 11, *)
extension UTMAppleConfigurationDevices {
    init(migrating oldConfig: UTMLegacyAppleConfiguration) {
        self.init()
        hasBalloon = oldConfig.isBalloonEnabled
        hasEntropy = oldConfig.isEntropyEnabled
        if #available(macOS 12, *) {
            hasAudio = oldConfig.isAudioEnabled
            hasKeyboard = oldConfig.isKeyboardEnabled
            pointer = oldConfig.isPointingEnabled ? .mouse : .disabled
        }
    }
}

// MARK: - Creating Apple config

@available(iOS, unavailable, message: "Apple Virtualization not available on iOS")
@available(macOS 11, *)
extension UTMAppleConfigurationDevices {
    func fillVZConfiguration(_ vzconfig: VZVirtualMachineConfiguration) {
        if hasBalloon {
            vzconfig.memoryBalloonDevices = [VZVirtioTraditionalMemoryBalloonDeviceConfiguration()]
        }
        if hasEntropy {
            vzconfig.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
        }
        #if arch(arm64)
        if #available(macOS 12, *) {
            if hasAudio {
                let audioConfiguration = VZVirtioSoundDeviceConfiguration()
                let audioInput = VZVirtioSoundDeviceInputStreamConfiguration()
                audioInput.source = VZHostAudioInputStreamSource()
                let audioOutput = VZVirtioSoundDeviceOutputStreamConfiguration()
                audioOutput.sink = VZHostAudioOutputStreamSink()
                audioConfiguration.streams = [audioInput, audioOutput]
                vzconfig.audioDevices = [audioConfiguration]
            }
            if hasKeyboard {
                vzconfig.keyboards = [VZUSBKeyboardConfiguration()]
            }
            if pointer != .disabled {
                let device: VZPointingDeviceConfiguration
                if #available(macOS 13, *) {
                    // FIXME: implement trackpad
                    device = VZUSBScreenCoordinatePointingDeviceConfiguration()
                } else {
                    device = VZUSBScreenCoordinatePointingDeviceConfiguration()
                }
                vzconfig.pointingDevices = [device]
            }
        }
        #endif
    }
}
