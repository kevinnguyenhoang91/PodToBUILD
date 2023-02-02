Pod::Spec.new do |s|
  s.name         = "RNCMaskedView"
  s.version      = "0.1.5"
  s.summary      = ""
  s.license      = ""

  s.authors      = ""
  s.homepage     = ""
  s.platforms    = { :ios => "9.0", :tvos => "9.0" }

  s.source       = { :git => "https://github.com/react-native-community/react-native-masked-view.git", :tag => "v#{s.version}" }
  s.source_files  = "ios/**/*.{h,m}"
  s.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ios\"" }
  
  s.dependency 'React-Core'
end
