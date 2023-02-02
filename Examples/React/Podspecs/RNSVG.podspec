Pod::Spec.new do |s|
  s.name             = 'RNSVG'
  s.version          = '12.1.0'
  s.summary          = ''
  s.license          = ''
  s.homepage         = ''
  s.authors          = 'Horcrux Chen'
  s.platforms        = { :ios => "9.0", :tvos => "9.2" }
  s.source           = { :git => 'https://github.com/react-native-community/react-native-svg.git', :tag => "v#{s.version}" }
  s.source_files     = 'ios/**/*.{h,m}'
  s.requires_arc     = true
  s.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ios\"" }
  s.dependency         'React-Core'
end
