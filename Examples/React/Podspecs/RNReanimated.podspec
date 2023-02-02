Pod::Spec.new do |s|
  s.name         = "RNReanimated"
  s.version      = "1.4.0"
  s.summary      = ""
  s.description  = <<-DESC
                  RNReanimated
                   DESC
  s.homepage     = "https://github.com/kmagiera/react-native-reanimated"
  s.license      = "MIT"
  # s.license    = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author       = { "author" => "author@domain.cn" }
  s.platforms    = { :ios => "9.0", :tvos => "9.0" }
  s.source       = { :git => "https://github.com/kmagiera/react-native-reanimated.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m}"
  s.requires_arc = true
  s.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ios/Nodes\" \"$(PODS_TARGET_SRCROOT)/ios/Transitioning\" \"$(PODS_TARGET_SRCROOT)/ios\"" }
  s.dependency "React-Core"
end

