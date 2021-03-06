//
//  Workspace.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

// __Podspec__
// "source": {
//  "git": "https://github.com/Flipboard/FLAnimatedImage.git",
//  "tag": "1.0.12"
// },
// ___
//
// Example:
// new_pod_repository(
//   name = "FLAnimatedImage",
//   url = "https://github.com/Flipboard/FLAnimatedImage/archive/1.0.12.zip",
//   strip_prefix = "FLAnimatedImage-1.0.12"
// )

enum WorkspaceError: Error {
    case unsupportedSource
    case invalidPodSpec
}

public struct PodRepositoryWorkspaceEntry: SkylarkConvertible {
    var name: String
    var url: String?
    var generateHeaderMap: Bool?
    var podspecURL: String?

    public func toSkylark() -> SkylarkNode {
        var args = [SkylarkFunctionArgument.named(name: "name", value: .string(name))]
        if let aUrl = url {
            args.append(.named(name: "url", value: .string(aUrl)))
        }
        if let aPodspecURL = podspecURL {
            args.append(.named(name: "podspec_url", value: .string(aPodspecURL)))
        }
        let generateHeaderMap = (self.generateHeaderMap ?? true) ? 1 : 0
        args.append(.named(name: "generate_header_map", value: .int(generateHeaderMap)))
        let repoSkylark = SkylarkNode.functionCall(name: "new_pod_repository",
                                                   arguments: args)
        return repoSkylark
    }
}

public struct PodsWorkspace: SkylarkConvertible {
    var pods: [PodRepositoryWorkspaceEntry] = []

    public static func vendorizePodspec(depName: String, shell: ShellContext) throws -> String {
        // If there is not an explicit podspec then copy it out of
        // the cocoapods repo
        let whichPodspec = shell.shellOut("pod spec which \(depName)")
            .standardOutputAsString
        guard !whichPodspec.isEmpty else {
            throw WorkspaceError.invalidPodSpec
        }
        guard let podSpecPath = whichPodspec.components(separatedBy:
        "\n").first else  {
            throw WorkspaceError.invalidPodSpec
        }
        let specsDir = "Vendor/Podspecs"
        try? FileManager.default.createDirectory(atPath: specsDir,
            withIntermediateDirectories: true,
            attributes: [:])
        guard let basenamePart = podSpecPath.split(separator: "/").last else {
            throw WorkspaceError.invalidPodSpec
        }
        let basename = String(basenamePart)
        let vendoredPath = "\(specsDir)/\(basename)"
        if FileManager.default.fileExists(atPath: vendoredPath) {
            try FileManager.default.removeItem(atPath: vendoredPath)
        }

        try FileManager.default.copyItem(atPath: podSpecPath,
            toPath: vendoredPath)
        return vendoredPath
    }

    public init(lockfile: Lockfile, shell: ShellContext) throws {
        let specRepoPods = Array(lockfile.specRepos.values).reduce(into: [String]()) {
            accum, next in
            accum.append(contentsOf: next)
        }

        var foundPods: Set<String> = Set()
        pods = try Array(lockfile.pods).compactMap {
            depStr in
            var depName: String!
            if let depDict = depStr as? [String: Any],
                let key = depDict.keys.first {
                depName = String(key.split(separator: " ")[0])
            } else if let key = depStr as? String {
                depName = String(key.split(separator: " ")[0])
            } else {
                fatalError("Unknown key" + String(describing: depStr))
            }
            // All pods are namespaced at a later point.
            let components = depName.split(separator: "/")
            if components.count > 1 {
                depName = String(components[0])
            }

            if foundPods.contains(depName) {
                return nil
            }
            foundPods.insert(depName)
            // let depName = ""
            var podspecSourceURL: String?
            var podspecURL: String?
            var sourceURL: String?
            // If the name has a slash, then it should refer to the podspec at
            // the path:
            // e.g.
            //  - React-Core/RCTWebSocket (from `Vendor/React/`)
            //  - ReactCommon/turbomodule/core (from `Vendor/React/ReactCommon`)
            if let externalDepInfo = lockfile.externalSources[depName] {
                if let pathStr = externalDepInfo[":path"] {
                    // If this is local path, it cannot end in a /
                    if pathStr.hasSuffix("/") {
                        sourceURL = String(pathStr.dropLast())
                    } else {
                        sourceURL = pathStr
                    }
                }
                let findPodspec: () -> String? = {
                    if let podspecURL = externalDepInfo[":podspec"] {
                        if podspecURL.hasSuffix(".podspec") {
                            return podspecURL
                        } else {
                            return podspecURL + "/" + depName + ".podspec"
                        }
                    }
                    return nil
                }

                if let externalPodspecURL = findPodspec() {
                    podspecURL = externalPodspecURL
                    if let podSpec = try? PodsWorkspace.getPodspec(path: externalPodspecURL) {
                        podspecSourceURL = try? PodsWorkspace.getURL(podSpec: podSpec)
                    }
                }
            }
            // If there is no podspec then we need to vendorize the podspec
            if podspecURL == nil && specRepoPods.contains(depName)  {
                podspecURL = try? PodsWorkspace.vendorizePodspec(depName: depName, shell: shell)
            }

            let implicitSourceURL = try? PodsWorkspace.getURL(depName: depName, shell: shell)
            return PodRepositoryWorkspaceEntry(
                name: depName,
                url: sourceURL ?? podspecSourceURL ?? implicitSourceURL,
                podspecURL: podspecURL
            )
        }
    }

    public func toSkylark() -> SkylarkNode {
        return .lines(pods.map { $0.toSkylark() })
    }

    static func getPodspec(path: String) throws -> PodSpec {
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
            JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
            let JSONPodspec = JSONFile as? JSONDict
        else {
            throw WorkspaceError.invalidPodSpec
        }
        return try PodSpec(JSONPodspec: JSONPodspec)
    }

    static func getURL(podSpec: PodSpec) throws -> String {
        guard let source = podSpec.source else {
            throw WorkspaceError.unsupportedSource
        }

        switch source {
        case let .git(url: gitURL, tag: .some(tag), commit: .none):
            guard gitURL.absoluteString.contains("github") else {
                throw WorkspaceError.unsupportedSource
            }
            return "\(gitURL.deletingPathExtension().absoluteString)/archive/\(tag ?? "").zip"
        case let .git(url: gitURL, tag: .none, commit: tag):
            return "\(gitURL.deletingPathExtension().absoluteString)/archive/\(tag ?? "").zip"
        case let .http(url: url):
            return url.absoluteString
        default:
            throw WorkspaceError.unsupportedSource
        }
    }

    static func getURL(depName: String, shell: ShellContext) throws -> String {
        // This command loads a JSON podspec from the cocoapods
        // repository.
        // We only do this to get the source if it isn't provided, in
        // order to export a github URL
        let whichPod = shell.shellOut("which pod").standardOutputAsString
        if whichPod.isEmpty {
            fatalError("RepoTools requires a cocoapod installation on host")
        }

        let podBin = whichPod.components(separatedBy: "\n")[0]
        let localSpec = shell.command(podBin, arguments: ["spec", "which", depName])
        guard localSpec.terminationStatus == 0 else {
            throw WorkspaceError.invalidPodSpec
        }
        let path = String(localSpec.standardOutputAsString.components(separatedBy:
            "\n")[0])
        let podSpec = try PodsWorkspace.getPodspec(path: path)
        return try PodsWorkspace.getURL(podSpec: podSpec)
    }
}
