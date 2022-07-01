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

@available(iOS, unavailable, message: "Apple Virtualization not available on iOS")
@available(macOS 11, *)
struct UTMAppleConfigurationBoot: Codable {
    enum OperatingSystem: String, CaseIterable, Identifiable, Codable {
        var id: String {
            rawValue
        }
        case linux = "Linux"
        case macOS = "macOS"
    }
    
    var operatingSystem: OperatingSystem
    var linuxKernelURL: URL?
    var linuxCommandLine: String?
    var linuxInitialRamdiskURL: URL?
    
    private enum CodingKeys: String, CodingKey {
        case operatingSystem = "OperatingSystem"
        case linuxKernelPath = "LinuxKernelPath"
        case linuxCommandLine = "LinuxCommandLine"
        case linuxInitialRamdiskPath = "LinuxInitialRamdiskPath"
    }
    
    init(from decoder: Decoder) throws {
        guard let dataURL = decoder.userInfo[.dataURL] as? URL else {
            throw UTMAppleConfigurationError.invalidDataURL
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        operatingSystem = try container.decode(OperatingSystem.self, forKey: .operatingSystem)
        if let linuxKernelPath = try container.decodeIfPresent(String.self, forKey: .linuxKernelPath) {
            linuxKernelURL = dataURL.appendingPathComponent(linuxKernelPath)
        }
        linuxCommandLine = try container.decodeIfPresent(String.self, forKey: .linuxCommandLine)
        if let linuxInitialRamdiskPath = try container.decodeIfPresent(String.self, forKey: .linuxInitialRamdiskPath) {
            linuxInitialRamdiskURL = dataURL.appendingPathComponent(linuxInitialRamdiskPath)
        }
    }
    
    init(for operatingSystem: OperatingSystem, linuxKernelURL: URL? = nil) throws {
        self.operatingSystem = operatingSystem
        self.linuxKernelURL = linuxKernelURL
        if operatingSystem == .linux && linuxKernelURL == nil {
            throw UTMAppleConfigurationError.kernelNotSpecified
        }
    }
    
    init(from linux: VZLinuxBootLoader) {
        self.operatingSystem = .linux
        self.linuxKernelURL = linux.kernelURL
        self.linuxCommandLine = linux.commandLine
        self.linuxInitialRamdiskURL = linux.initialRamdiskURL
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(operatingSystem, forKey: .operatingSystem)
        try container.encodeIfPresent(linuxKernelURL?.lastPathComponent, forKey: .linuxKernelPath)
        try container.encodeIfPresent(linuxCommandLine, forKey: .linuxCommandLine)
        try container.encodeIfPresent(linuxInitialRamdiskURL?.lastPathComponent, forKey: .linuxInitialRamdiskPath)
    }
    
    func vzBootloader() -> VZBootLoader? {
        switch operatingSystem {
        case .linux:
            guard let linuxKernelURL = linuxKernelURL else {
                return nil
            }
            let linux = VZLinuxBootLoader(kernelURL: linuxKernelURL)
            linux.initialRamdiskURL = linuxInitialRamdiskURL
            if let linuxCommandLine = linuxCommandLine {
                linux.commandLine = linuxCommandLine
            }
            return linux
        case .macOS:
            #if arch(arm64)
            if #available(macOS 12, *) {
                return VZMacOSBootLoader()
            }
            #endif
            return nil
        }
    }
}

// MARK: - Conversion of old config format

@available(iOS, unavailable, message: "Apple Virtualization not available on iOS")
@available(macOS 11, *)
extension UTMAppleConfigurationBoot {
    init(migrating oldBoot: Bootloader) {
        switch oldBoot.operatingSystem {
        case .macOS: operatingSystem = .macOS
        case .Linux: operatingSystem = .linux
        }
        linuxKernelURL = oldBoot.linuxKernelURL
        linuxCommandLine = oldBoot.linuxCommandLine
        linuxInitialRamdiskURL = oldBoot.linuxInitialRamdiskURL
    }
}
