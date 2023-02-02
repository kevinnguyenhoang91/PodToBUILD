load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application", "macos_unit_test")
load("@rules_cc//cc:defs.bzl", "objc_library")

objc_library(
    name = "ObjcSupport",
    srcs = glob(["Sources/ObjcSupport/*.m"]),
    hdrs = glob(["Sources/ObjcSupport/include/*"]),
    includes = ["Sources/ObjcSupport/include"]
)

# PodToBUILD is a core library enabling Starlark code generation
swift_library(
    name = "PodToBUILD",
    srcs = glob(["Sources/PodToBUILD/*.swift"]),
    deps = [":ObjcSupport", "@podtobuild-Yams//:Yams"],
    copts = ["-swift-version", "5"],
)

# Compiler
macos_command_line_application(
    name = "Compiler",
    minimum_os_version = "10.13",
    deps = [":CompilerLib"],
)

swift_library(
    name = "CompilerLib",
    srcs = glob(["Sources/Compiler/*.swift"]),
    deps = [":PodToBUILD"],
    copts = ["-swift-version", "5"],
)

# RepoTools
macos_command_line_application(
    name = "RepoTools",
    minimum_os_version = "10.13",
    deps = [":RepoToolsLib"],
)

swift_library(
    name = "RepoToolsLib",
    srcs = glob(["Sources/RepoTools/*.swift"]),
    deps = [":RepoToolsCore"],
    copts = ["-swift-version", "5"],
)

swift_library(
    name = "RepoToolsCore",
    srcs = glob(["Sources/RepoToolsCore/*.swift"]),
    deps = [":PodToBUILD"],
    copts = ["-swift-version", "4"],
)

alias(name = "update_pods", actual = "//bin:update_pods")

# This tests RepoToolsCore and Starlark logic
swift_library(
    name = "PodToBUILDTestsLib",
    srcs = glob(["Tests/PodToBUILDTests/*.swift"]),
    deps = [":RepoToolsCore", "@podtobuild-SwiftCheck//:SwiftCheck"],
    data = glob(["Examples/**/*.podspec.json"])
)

macos_unit_test(
    name = "PodToBUILDTests",
    deps = [":PodToBUILDTestsLib"],
    minimum_os_version = "10.13",
)

swift_library(
    name = "BuildTestsLib",
    srcs = glob(["Tests/BuildTests/*.swift"]),
    deps = [":RepoToolsCore", "@podtobuild-SwiftCheck//:SwiftCheck"],
    data = glob(["Examples/**/*.podspec.json"])
)

# This tests RepoToolsCore and Starlark logic
macos_unit_test(
    name = "BuildTests",
    deps = [":BuildTestsLib"],
    minimum_os_version = "10.13",
)

load(
    "@bazel_tools//tools/python:toolchain.bzl",
    "py_runtime_pair",
)

py_runtime(
    name = "python3",
    interpreter_path = "/usr/bin/python3",
    stub_shebang = "#!/usr/bin/env PYTHONHASHSEED=1 python3",
    python_version = "PY3",
)

py_runtime(
    name = "python2",
    interpreter_path = "/usr/bin/python3",
    stub_shebang = "#!/usr/bin/env PYTHONHASHSEED=1 python3",
    python_version = "PY2",
)

py_runtime_pair(
    name = "py",
    py3_runtime = ":python3",
    py2_runtime = ":python2",
)

toolchain(
    name = "py-toolchain",
    toolchain = ":py",
    toolchain_type = "@bazel_tools//tools/python:toolchain_type",
)
