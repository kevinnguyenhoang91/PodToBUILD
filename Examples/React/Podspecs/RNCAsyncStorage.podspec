Pod::Spec.new do |s|
  s.name         = 'RNCAsyncStorage'
  s.version      = '1.13.2'
  s.summary      = ''
  s.license      = ''

  s.authors      = ''
  s.homepage     = ''
  s.platforms    = { :ios => "9.0", :tvos => "9.2", :osx => "10.14" }

  s.source       = { :git => "https://github.com/react-native-async-storage/async-storage.git", :tag => "v#{s.version}" }
  s.source_files  = "ios/**/*.{h,m}"
  s.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ios\"" }
  s.dependency 'React-Core'
end
