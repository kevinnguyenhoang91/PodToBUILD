ROOT_REPOSITORY = "ReactNative"

# React Native

REACT_NATIVE_VERSION = "0.64.1"

REACT_NATIVE_URL = "https://github.com/facebook/react-native/archive/v%s.zip" % REACT_NATIVE_VERSION

REACT_NATIVE_STRIP_PREFIX = "react-native-%s" % REACT_NATIVE_VERSION

PATCH_CMDS = """
sed -i '' 's/\/\/Vendor/\@{root_repository}\/\/Vendor/g' BUILD.bazel
sed -i '' 's/-IVendor\//-Iexternal\/{root_repository}\/Vendor\//g' BUILD.bazel
sed -i '' 's/\"Vendor\//\"external\/{root_repository}\/Vendor\//g' BUILD.bazel
sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
""".format(**dict(
    root_repository = ROOT_REPOSITORY,
))

new_pod_repository(
  name = "React",
  url = REACT_NATIVE_URL,
  strip_prefix = REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    cp ../../../package.json ../package.json
    pushd ..
        yarn install
    popd
    # FBReactNativeSpec prepare_command
    SRCS_DIR=$PWD/Libraries 
    CODEGEN_MODULES_OUTPUT_DIR=$PWD/React/FBReactNativeSpec/FBReactNativeSpec 
    CODEGEN_MODULES_LIBRARY_NAME=FBReactNativeSpec 
    sh scripts/generate-specs.sh
    
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-Core",
  url = REACT_NATIVE_URL,
  strip_prefix = REACT_NATIVE_STRIP_PREFIX,  
  podspec_url = "Podspecs/React-Core.podspec",
  install_script = """
    mkdir -p pod_support/React
    find React/ -name "*.h" -exec mv {} pod_support/React/ \;
    find Libraries/WebSocket -name "*.h" -exec mv {} pod_support/React/ \;
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "RCT-Folly",
  url = "https://github.com/facebook/folly/archive/v2020.01.13.00.zip",
  podspec_url = "Podspecs/RCT-Folly.podspec",
  install_script = """
    __INIT_REPO__
    # __has_include erroneously returns true for damangle.h, which later causes an link error
    sed -i '' 's,__has_include(<demangle.h>),false,g' folly/detail/Demangle.h
    sed -i '' 's,atomic_notify_one(state),folly::atomic_notify_one(state),g' folly/synchronization/DistributedMutex-inl.h
    sed -i '' 's,atomic_wait_until,folly::atomic_wait_until,g' folly/synchronization/DistributedMutex-inl.h
    # This isn't actually necessary but nice.
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
  user_options = [
    "Futures.deps += //Vendor/glog:glog",
    "Futures_cxx.deps += //Vendor/glog:glog",
  ]
)

new_pod_repository(
  name = "DoubleConversion",
  url = 'https://github.com/google/double-conversion/archive/v1.1.6.zip',
  podspec_url = 'Vendor/React/third-party-podspecs/DoubleConversion.podspec',
  install_script = """
    # prepare_command
    mv src double-conversion
    __INIT_REPO__
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "glog",
  url = 'https://github.com/google/glog/archive/v0.3.5.zip',
  podspec_url = 'Vendor/React/third-party-podspecs/glog.podspec',
  install_script = """
    # prepare_command
    sed -i '' 's,spec.prepare_command,#spec.prepare_command,g' glog.podspec
    sh ../React/scripts/ios-configure-glog.sh
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "libevent",
  url = "https://github.com/libevent/libevent/archive/release-2.1.12-stable.zip",
  podspec_url = "Vendor/React/third-party-podspecs/libevent.podspec",
  install_script = """
    # prepare_command
    touch evconfig-private.h
    cp -Lf ../../Patches/libevent/event-config.h include/event2/event-config.h
    __INIT_REPO__
    # This isn't actually necessary but nice.
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "boost-for-react-native",
  url = "https://github.com/react-native-community/boost-for-react-native/archive/v1.63.0-0.zip",
  podspec_url = "Podspecs/boost-for-react-native.podspec.json",
  install_script = """
    __INIT_REPO__
    # This isn't actually necessary but nice.
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "YogaKit",
  url = "https://github.com/facebook/yoga/archive/1.18.0.zip",
  install_script = """
    __INIT_REPO__
    %s
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    sed -i '' 's/import yoga;/import ReactNativeVendor_Yoga_Yoga;/g' YogaKit/Source/YGLayoutExtensions.swift
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "CocoaAsyncSocket",
  url = "https://github.com/robbiehanson/CocoaAsyncSocket/archive/7.6.5.zip",
  podspec_url = "Podspecs/CocoaAsyncSocket.podspec.json",
  install_script = """
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "FBLazyVector",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/FBLazyVector" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' FBLazyVector.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "FBReactNativeSpec",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/React/FBReactNativeSpec" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,../../scripts/react_native_pods.rb,../React/scripts/react_native_pods.rb,g' FBReactNativeSpec.podspec
    sed -i '' 's,".."\, "..",".."\, "React",g' FBReactNativeSpec.podspec
    sed -i '' 's,$(PODS_TARGET_SRCROOT)/React/FBReactNativeSpec,$(PODS_TARGET_SRCROOT),g' FBReactNativeSpec.podspec
    __INIT_REPO__
    cp -RLf ../React/React/FBReactNativeSpec/FBReactNativeSpec ./
    %s
  """ % PATCH_CMDS,
  user_options = [
    "FBReactNativeSpec.copts += -IVendor/React-Core/pod_support/Headers/Public_cpp"
  ]
)

new_pod_repository(
  name = "hermes-engine",
  url = "https://github.com/facebook/hermes/releases/download/v0.7.2/hermes-runtime-darwin-v0.7.2.tar.gz",
  podspec_url = "Podspecs/hermes-engine.podspec",
  install_script = """
    lipo -remove armv7 -remove armv7s -remove i386 destroot/Library/Frameworks/iphoneos/hermes.framework/hermes -output destroot/Library/Frameworks/iphoneos/hermes.framework/hermes
    lipo -remove armv7 -remove armv7s destroot/Library/Frameworks/iphoneos/hermes.framework.dSYM/Contents/Resources/DWARF/hermes -output destroot/Library/Frameworks/iphoneos/hermes.framework.dSYM/Contents/Resources/DWARF/hermes
    __INIT_REPO__
    sed -i '' 's,apple_static_framework_import,apple_dynamic_framework_import,g' BUILD.bazel
    mv destroot/include/hermes pod_support/Headers/Public/
    mv destroot/include/jsi pod_support/Headers/Public/
    rm -rf destroot/Library/Frameworks/macosx || true
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "RCTRequired",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/RCTRequired" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' RCTRequired.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "RCTTypeSafety",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/TypeSafety" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' RCTTypeSafety.podspec
    sed -i '' 's,$(PODS_TARGET_SRCROOT)/Libraries/TypeSafety,$(PODS_TARGET_SRCROOT),g' RCTTypeSafety.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-callinvoker",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon/callinvoker" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-callinvoker.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-CoreModules",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/React/CoreModules" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-CoreModules.podspec
    sed -i '' 's,$(PODS_TARGET_SRCROOT)/React/CoreModules,$(PODS_TARGET_SRCROOT),g' React-CoreModules.podspec
    sed -i '' 's,**/*.{c\,m\,mm\,cpp},**/*.{c\,m\,mm\,cpp\,h\,hpp},g' React-CoreModules.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-cxxreact",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon/cxxreact" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-cxxreact.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-Fabric",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "package.json",".."\, "React"\, "package.json",g' React-Fabric.podspec
    sed -i '' 's,$(PODS_TARGET_SRCROOT)/ReactCommon,$(PODS_TARGET_SRCROOT),g' React-Fabric.podspec
    __INIT_REPO__
    # This isn't actually necessary but nice.
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-graphics",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon/react/renderer/graphics" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, ".."\, ".."\, ".."\,,".."\, "React"\,,g' React-graphics.podspec
    sed -i '' 's,$(PODS_TARGET_SRCROOT)/../../../,$(PODS_TARGET_SRCROOT),g' React-graphics.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-jsi",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon/jsi" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-jsi.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-jsiexecutor",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon/jsiexecutor" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-jsiexecutor.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-jsinspector",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon/jsinspector" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-jsinspector.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-perflogger",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon/reactperflogger" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-perflogger.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-RCTActionSheet",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/ActionSheetIOS" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-RCTActionSheet.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-RCTAnimation",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/NativeAnimation" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-RCTAnimation.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-RCTBlob",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/Blob" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-RCTBlob.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

# new_pod_repository(
#   name = "React-RCTFabric",
#   url = REACT_NATIVE_URL,
#   strip_prefix = "%s/React" % REACT_NATIVE_STRIP_PREFIX,
#   install_script = """
#     sed -i '' 's,".."\, "package.json",".."\, "React"\, "package.json",g' React-RCTFabric.podspec
#     sed -i '' 's,$(PODS_TARGET_SRCROOT)/ReactCommon,$(PODS_ROOT)/React/ReactCommon,g' React-RCTFabric.podspec
#     __INIT_REPO__
#     %s
#   """ % PATCH_CMDS,
# )

new_pod_repository(
  name = "React-RCTImage",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/Image" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-RCTImage.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-RCTLinking",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/LinkingIOS" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-RCTLinking.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-RCTNetwork",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/Network" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-RCTNetwork.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-RCTSettings",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/Settings" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-RCTSettings.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-RCTText",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/Text" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-RCTText.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-RCTVibration",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/Libraries/Vibration" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-RCTVibration.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "React-runtimeexecutor",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon/runtimeexecutor" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "..",".."\, "React",g' React-runtimeexecutor.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "ReactCommon",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon" % REACT_NATIVE_STRIP_PREFIX,
  install_script = """
    sed -i '' 's,".."\, "package.json",".."\, "React"\, "package.json",g' ReactCommon.podspec
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "Yoga",
  url = REACT_NATIVE_URL,
  strip_prefix = "%s/ReactCommon/yoga" % REACT_NATIVE_STRIP_PREFIX,
  podspec_url = "Podspecs/Yoga.podspec",
  install_script = """
    sed -i '' 's,../../package.json,../React/package.json,g' Yoga.podspec
    __INIT_REPO__
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    %s
  """ % PATCH_CMDS,
)

# Flipper

new_pod_repository(
  name = "OpenSSL-Universal",
  url = 'https://github.com/krzyzanowskim/OpenSSL/archive/refs/tags/1.1.180.zip',
  strip_prefix = "OpenSSL-1.1.180",
  podspec_url = "Podspecs/OpenSSL-Universal.podspec",
  install_script = """
    lipo -thin arm64 Frameworks/iphoneos/OpenSSL.framework/OpenSSL -output Frameworks/iphoneos/OpenSSL.framework/OpenSSL
    lipo -thin x86_64 Frameworks/iphonesimulator/OpenSSL.framework/OpenSSL -output Frameworks/iphonesimulator/OpenSSL.framework/OpenSSL
    lipo -create Frameworks/iphoneos/OpenSSL.framework/OpenSSL Frameworks/iphonesimulator/OpenSSL.framework/OpenSSL -output Frameworks/iphoneos/OpenSSL.framework/OpenSSL
    rm -rf Frameworks/iphonesimulator || true
    rm -rf Frameworks/macos || true
    rm -rf Frameworks/macos_catalyst || true
    rm -rf Frameworks/OpenSSL.xcframework || true
    rm -rf iphoneos || true
    rm -rf iphonesimulator || true
    rm -rf macos || true
    rm -rf macos_catalyst || true
    __INIT_REPO__
    sed -i '' 's,apple_static_framework_import,apple_dynamic_framework_import,g' BUILD.bazel
    # This isn't actually necessary but nice.
    rm -rf pod_support/Headers/Public/*
    sed -i '' 's,#elif defined(__APPLE__) && defined (__arm__) && defined (__ARM_ARCH_7A__),,g' Frameworks/iphoneos/OpenSSL.framework/Headers/opensslconf.h
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "Flipper",
  url = "https://github.com/facebook/flipper/archive/v0.75.1.zip",
  podspec_url = "Podspecs/Flipper.podspec.json",
  install_script = """
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly/,follyflipper/,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,namespace folly,namespace follyflipper,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly::,follyflipper::,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_reqctx_use_hazptr,follyflipper_reqctx_use_hazptr,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_hazptr_use_executor,follyflipper_hazptr_use_executor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_target_delay,follyflipper_codel_target_delay,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_interval,follyflipper_codel_interval,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_iothreadpoolexecutor,follyflipper_dynamic_iothreadpoolexecutor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_cputhreadpoolexecutor,follyflipper_dynamic_cputhreadpoolexecutor,g' "{}" \;
    __INIT_REPO__
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "Flipper-Folly",
  url = "https://github.com/priteshrnandgaonkar/folly/archive/refs/tags/v2020.04.06.01.zip",
  podspec_url = "Podspecs/Flipper-Folly.podspec.json",
  strip_prefix = "folly-2020.04.06.01",
  install_script = """
    mv folly follyflipper
    sed -i '' 's,folly/,follyflipper/,g' Flipper-Folly.podspec.json
    sed -i '' 's,"folly","follyflipper",g' Flipper-Folly.podspec.json
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly/,follyflipper/,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,namespace folly,namespace follyflipper,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly::,follyflipper::,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_reqctx_use_hazptr,follyflipper_reqctx_use_hazptr,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_hazptr_use_executor,follyflipper_hazptr_use_executor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_target_delay,follyflipper_codel_target_delay,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_interval,follyflipper_codel_interval,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_iothreadpoolexecutor,follyflipper_dynamic_iothreadpoolexecutor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_cputhreadpoolexecutor,follyflipper_dynamic_cputhreadpoolexecutor,g' "{}" \;
    __INIT_REPO__
    sed -i '' 's,__has_include(<demangle.h>),false,g' follyflipper/detail/Demangle.h
    # This isn't actually necessary but nice.
    rm -rf pod_support/Headers/Public/*
    cp -f ../../Patches/Flipper-Folly/follyflipper/memory/detail/MallocImpl.cpp follyflipper/memory/detail/MallocImpl.cpp
    cp -f ../../Patches/Flipper-Folly/follyflipper/portability/SysUio.cpp follyflipper/portability/SysUio.cpp
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "Flipper-RSocket",
  url = "https://github.com/priteshrnandgaonkar/rsocket-cpp/archive/refs/tags/0.11.0.zip",
  strip_prefix = "rsocket-cpp-0.11.0",
  podspec_url = "Podspecs/Flipper-RSocket.podspec.json",
  install_script = """
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly/,follyflipper/,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,namespace folly,namespace follyflipper,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly::,follyflipper::,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_reqctx_use_hazptr,follyflipper_reqctx_use_hazptr,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_hazptr_use_executor,follyflipper_hazptr_use_executor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_target_delay,follyflipper_codel_target_delay,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_interval,follyflipper_codel_interval,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_iothreadpoolexecutor,follyflipper_dynamic_iothreadpoolexecutor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_cputhreadpoolexecutor,follyflipper_dynamic_cputhreadpoolexecutor,g' "{}" \;
    __INIT_REPO__
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "Flipper-DoubleConversion",
  url = "https://github.com/google/double-conversion/archive/refs/tags/v1.1.6.zip",
  strip_prefix = "double-conversion-1.1.6",
  podspec_url = "Podspecs/Flipper-DoubleConversion.podspec.json",
  install_script = """
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly/,follyflipper/,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,namespace folly,namespace follyflipper,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly::,follyflipper::,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_reqctx_use_hazptr,follyflipper_reqctx_use_hazptr,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_hazptr_use_executor,follyflipper_hazptr_use_executor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_target_delay,follyflipper_codel_target_delay,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_interval,follyflipper_codel_interval,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_iothreadpoolexecutor,follyflipper_dynamic_iothreadpoolexecutor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_cputhreadpoolexecutor,follyflipper_dynamic_cputhreadpoolexecutor,g' "{}" \;
    mv src double-conversion
    __INIT_REPO__
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "Flipper-Glog",
  url = "https://github.com/priteshrnandgaonkar/glog/archive/v0.3.9.zip",
  podspec_url = "Podspecs/Flipper-Glog.podspec",
  install_script = """
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly/,follyflipper/,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,namespace folly,namespace follyflipper,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly::,follyflipper::,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_reqctx_use_hazptr,follyflipper_reqctx_use_hazptr,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_hazptr_use_executor,follyflipper_hazptr_use_executor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_target_delay,follyflipper_codel_target_delay,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_interval,follyflipper_codel_interval,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_iothreadpoolexecutor,follyflipper_dynamic_iothreadpoolexecutor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_cputhreadpoolexecutor,follyflipper_dynamic_cputhreadpoolexecutor,g' "{}" \;
    sh ../React/scripts/ios-configure-glog.sh
    __INIT_REPO__
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "Flipper-PeerTalk",
  url = "https://github.com/priteshrnandgaonkar/peertalk/archive/v0.0.3.zip",
  podspec_url = "Podspecs/Flipper-PeerTalk.podspec",
  install_script = """
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly/,follyflipper/,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,namespace folly,namespace follyflipper,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly::,follyflipper::,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_reqctx_use_hazptr,follyflipper_reqctx_use_hazptr,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_hazptr_use_executor,follyflipper_hazptr_use_executor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_target_delay,follyflipper_codel_target_delay,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_interval,follyflipper_codel_interval,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_iothreadpoolexecutor,follyflipper_dynamic_iothreadpoolexecutor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_cputhreadpoolexecutor,follyflipper_dynamic_cputhreadpoolexecutor,g' "{}" \;
    __INIT_REPO__
    rm -rf pod_support/Headers/Public/*
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "FlipperKit",
  url = "https://github.com/facebook/flipper/archive/v0.75.1.zip",
  podspec_url = "Podspecs/FlipperKit.podspec.json",
  install_script = """
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly/,follyflipper/,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,namespace folly,namespace follyflipper,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly::,follyflipper::,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_reqctx_use_hazptr,follyflipper_reqctx_use_hazptr,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,folly_hazptr_use_executor,follyflipper_hazptr_use_executor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_target_delay,follyflipper_codel_target_delay,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,codel_interval,follyflipper_codel_interval,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_iothreadpoolexecutor,follyflipper_dynamic_iothreadpoolexecutor,g' "{}" \;
    find . \( -iname "*.h" -o -iname "*.cpp" -o -iname "*.m" -o -iname "*.mm" \) -exec sed -i '' 's,dynamic_cputhreadpoolexecutor,follyflipper_dynamic_cputhreadpoolexecutor,g' "{}" \;
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

new_pod_repository(
  name = "Flipper-Boost-iOSX",
  url = "https://github.com/priteshrnandgaonkar/boost-iosx/archive/refs/tags/1.76.0.1.16.tar.gz",
  strip_prefix = "boost-iosx-1.76.0.1.16",
  podspec_url = "Podspecs/Flipper-Boost-iOSX.podspec",
  install_script = """
    LIBS=(boost_thread boost_program_options boost_system boost_regex boost_context boost_filesystem)
    for i in "${LIBS[@]}"
    do
      lipo -thin arm64 frameworks/$i.xcframework/ios-arm64/lib$i.a -output frameworks/$i.xcframework/ios-arm64/lib$i.a
      lipo -thin x86_64 frameworks/$i.xcframework/ios-arm64_i386_x86_64-simulator/lib$i.a -output frameworks/$i.xcframework/ios-arm64_i386_x86_64-simulator/lib$i.a
      lipo -create frameworks/$i.xcframework/ios-arm64/lib$i.a frameworks/$i.xcframework/ios-arm64_i386_x86_64-simulator/lib$i.a -output frameworks/lib$i.a
    done
    __INIT_REPO__
    %s
  """ % PATCH_CMDS,
)

# Third-party React Native Modules

new_pod_repository(
    name = "RNCMaskedView",
    url = "https://registry.yarnpkg.com/@react-native-community/masked-view/-/masked-view-0.1.10.tgz",
    strip_prefix = "package",
    install_script = """
        __INIT_REPO__
        %s
        sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/RNCMaskedView.podspec",
)

new_pod_repository(
    name = "RNGestureHandler",
    url = "https://registry.yarnpkg.com/react-native-gesture-handler/-/react-native-gesture-handler-1.8.0.tgz",
    strip_prefix = "package",
    install_script = """
        __INIT_REPO__
        %s
        sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/RNGestureHandler.podspec",
)

new_pod_repository(
    name = "RNReanimated",
    url = "https://registry.yarnpkg.com/react-native-reanimated/-/react-native-reanimated-1.13.1.tgz",
    strip_prefix = "package",
    install_script = """
        __INIT_REPO__
        %s
        sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/RNReanimated.podspec",
)

new_pod_repository(
    name = "react-native-safe-area-context",
    url = "https://registry.yarnpkg.com/react-native-safe-area-context/-/react-native-safe-area-context-3.2.0.tgz",
    strip_prefix = "package",
    install_script = """
        __INIT_REPO__
        %s
        sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/react-native-safe-area-context.podspec",
)

new_pod_repository(
    name = "RNScreens",
    url = "https://registry.yarnpkg.com/react-native-screens/-/react-native-screens-2.11.0.tgz",
    strip_prefix = "package",
    install_script = """
        __INIT_REPO__
        %s
        sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/RNScreens.podspec",
)

new_pod_repository(
    name = "react-native-view-shot",
    url = "https://registry.yarnpkg.com/react-native-view-shot/-/react-native-view-shot-3.1.2.tgz",
    strip_prefix = "package",
    install_script = """
        __INIT_REPO__
        %s
        sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/react-native-view-shot.podspec",
)

new_pod_repository(
    name = "rn-fetch-blob",
    url = "https://github.com/joltup/rn-fetch-blob/archive/v0.12.0.tar.gz",
    strip_prefix = "rn-fetch-blob-0.12.0",
    install_script = """
    __INIT_REPO__
    %s
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/rn-fetch-blob.podspec",
)

new_pod_repository(
    name = "RNCAsyncStorage",
    url = "https://registry.yarnpkg.com/@react-native-async-storage/async-storage/-/async-storage-1.13.2.tgz",
    strip_prefix = "package",
    install_script = """
    __INIT_REPO__
    %s
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/RNCAsyncStorage.podspec",
)

new_pod_repository(
    name = "RNSVG",
    url = "https://registry.yarnpkg.com/react-native-svg/-/react-native-svg-12.1.0.tgz",
    strip_prefix = "package",
    install_script = """
    __INIT_REPO__
    %s
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/RNSVG.podspec",
)

new_pod_repository(
    name = "RNDateTimePicker",
    url = "https://registry.yarnpkg.com/@react-native-community/datetimepicker/-/datetimepicker-3.0.8.tgz",
    strip_prefix = "package",
    install_script = """
    __INIT_REPO__
    %s
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/RNDateTimePicker.podspec",
)

new_pod_repository(
    name = "RNVectorIcons",
    url = "https://registry.yarnpkg.com/react-native-vector-icons/-/react-native-vector-icons-8.0.0.tgz",
    strip_prefix = "package",
    install_script = """
    __INIT_REPO__
    %s
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/RNVectorIcons.podspec",
)

new_pod_repository(
    name = "react-native-mmkv-storage",
    url = "https://github.com/diesel-engineer/react-native-mmkv-storage/archive/refs/tags/0.4.6.zip",
    strip_prefix = "react-native-mmkv-storage-0.4.6",
    install_script = """
    __INIT_REPO__
    %s
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
)

BUILD_MMKV_FRAMEWORK = """
# Optional Value
####################

PROJECT_NAME=MMKV
TARGET_NAME=MMKV

####################

# Required Values
####################

FRAMEWORK_NAME="${PROJECT_NAME}"
CONFIGURATION=Release
BUILD_SIMULATOR_DIR=${PWD}/build-sim
BUILD_DEVICE_DIR=${PWD}/build-device
BUILD_UNIVERSAL_DIR=${PWD}/build-universal
SIMULATOR_LIBRARY_PATH="${BUILD_SIMULATOR_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework"
DEVICE_LIBRARY_PATH="${BUILD_DEVICE_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework"
UNIVERSAL_LIBRARY_DIR="${BUILD_UNIVERSAL_DIR}/${CONFIGURATION}-iphoneuniversal"
FRAMEWORK="${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"
mkdir -p "${BUILD_UNIVERSAL_DIR}"

######################

# Build Frameworks
######################

# Extra build flags
EXTRA_BUILD_FLAGS=()

# Build static framework
EXTRA_BUILD_FLAGS+=( MACH_O_TYPE=staticlib )
EXTRA_BUILD_FLAGS+=( IPHONEOS_DEPLOYMENT_TARGET=11.0 )
EXTRA_BUILD_FLAGS+=( EXCLUDED_ARCHS[sdk=iphoneos*]=armv7 )
EXTRA_BUILD_FLAGS+=( VALID_ARCHS=arm64 )

# Swift version
EXTRA_BUILD_FLAGS+=( SWIFT_VERSION=5.0 )

# Bitcode (Xcode >= 9.0)
EXTRA_BUILD_FLAGS+=( ENABLE_BITCODE=NO )

xcodebuild \
    -workspace ${PROJECT_NAME}.xcworkspace \
    -scheme ${TARGET_NAME} \
    -sdk iphonesimulator \
    -configuration ${CONFIGURATION} \
    -arch x86_64 \
    clean build \
    CONFIGURATION_BUILD_DIR=${BUILD_SIMULATOR_DIR}/${CONFIGURATION}-iphonesimulator \
    VALID_ARCHS=x86_64 \
    ${EXTRA_BUILD_FLAGS[@]} \
        &> build_simulator.log
    
xcodebuild \
    -workspace ${PROJECT_NAME}.xcworkspace \
    -scheme ${TARGET_NAME} \
    -sdk iphoneos \
    -configuration ${CONFIGURATION} \
    -arch arm64 -arch armv7 \
    clean build \
    CONFIGURATION_BUILD_DIR=${BUILD_DEVICE_DIR}/${CONFIGURATION}-iphoneos \
    VALID_ARCHS='arm64 armv7' \
    ${EXTRA_BUILD_FLAGS[@]} \
        &> build_device.log

######################

# Create directory for universal
######################

rm -rf "${UNIVERSAL_LIBRARY_DIR}"
mkdir -p "${UNIVERSAL_LIBRARY_DIR}"
mkdir -p "${FRAMEWORK}"

######################

# Copy files Framework
######################

cp -r "${DEVICE_LIBRARY_PATH}/." "${FRAMEWORK}"

######################

# Make an universal binary
######################

lipo "${SIMULATOR_LIBRARY_PATH}/${FRAMEWORK_NAME}" "${DEVICE_LIBRARY_PATH}/${FRAMEWORK_NAME}" -create -output "${FRAMEWORK}/${FRAMEWORK_NAME}" | echo

######################

# For Swift framework, Swiftmodule needs to be copied in the universal framework
######################

if [ -d "${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" ]; then
    cp -f ${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/* "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftmodule/" | echo
fi
if [ -d "${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" ]; then
    cp -f ${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/* "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftmodule/" | echo
fi
if [ -d "${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftinterface/" ]; then
    cp -f ${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftinterface/* "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftinterface/" | echo
fi
if [ -d "${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftinterface/" ]; then
    cp -f ${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftinterface/* "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftinterface/" | echo
fi

######################

# On Release, copy the result to release directory
######################

OUTPUT_DIR="Output/${FRAMEWORK_NAME}-${CONFIGURATION}-iphoneuniversal/"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
cp -r "${FRAMEWORK}" "$OUTPUT_DIR"
echo '
framework module MMKV {
    umbrella header "MMKV.h"
    
    link "c++"
    link "z"
    
    export *
    module * { export * }
}
' > "$OUTPUT_DIR"/${TARGET_NAME}.framework/Modules/module.modulemap
"""

new_pod_repository(
    name = "MMKV",
    url = "https://github.com/Tencent/MMKV/archive/refs/tags/v1.2.7.zip",
    strip_prefix = "MMKV-1.2.7",
    install_script = """
    __INIT_REPO__
    %s
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    %s
    """ % (PATCH_CMDS, BUILD_MMKV_FRAMEWORK),
    podspec_url = "Podspecs/MMKV.podspec",
)

new_pod_repository(
    name = "react-native-webview",
    url = "https://registry.yarnpkg.com/react-native-webview/-/react-native-webview-11.4.3.tgz",
    strip_prefix = "package",
    install_script = """
    __INIT_REPO__
    %s
    sed -i '' 's,alwayslink = False,alwayslink = True,g' BUILD.bazel
    """ % PATCH_CMDS,
    podspec_url = "Podspecs/react-native-webview.podspec",
)

# podfile_deps.py picks up the workspace generated from cocoapods
# load("podfile_deps.py")
