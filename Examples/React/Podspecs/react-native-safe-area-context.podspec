Pod::Spec.new do |s|
  s.name         = "react-native-safe-area-context"
  s.version      = "0.6.0"
  s.platforms    = { :ios => "9.0", :tvos => "9.2" }

  s.source       = { :git => "https://github.com/th3rdwave/react-native-safe-area-context.git", :tag => "v#{s.version}" }
  s.source_files  = "ios/**/*.{h,m}"
  s.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ios/SafeAreaView\" \"$(PODS_TARGET_SRCROOT)/ios\"" }
  s.dependency 'React-Core'
end
