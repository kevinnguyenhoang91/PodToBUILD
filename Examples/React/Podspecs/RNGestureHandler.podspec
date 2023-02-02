Pod::Spec.new do |s|
  s.name         = "RNGestureHandler"
  s.version      = "1.5.6"
  s.summary      = ""
  s.homepage     = "https://github.com/software-mansion/react-native-gesture-handler"
  s.license      = "MIT"
  s.author       = ""
  s.platforms    = { :ios => "9.0", :tvos => "9.0" }
  s.source       = { :git => "https://github.com/software-mansion/react-native-gesture-handler", :tag => "#{s.version}" }
  s.source_files = "ios/**/*.{h,m}"
  s.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ios/Handlers\" \"$(PODS_TARGET_SRCROOT)/ios\"" }
  s.dependency "React-Core"

end
