Pod::Spec.new do |s|
  s.name         = "RNDateTimePicker"
  s.version      = '3.0.8'
  s.summary      = ''
  s.description  = ''
  s.license      = ''
  s.author       = ''
  s.homepage     = ''
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/react-native-community/datetimepicker", :tag => "v#{s.version}" }
  s.source_files = "ios/*.{h,m}"
  s.requires_arc = true
  s.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ios\"" }

  s.dependency "React-Core"
end
