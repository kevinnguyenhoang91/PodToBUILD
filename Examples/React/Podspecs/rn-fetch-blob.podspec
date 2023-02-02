Pod::Spec.new do |s|
  s.name             = 'rn-fetch-blob'
  s.version          = '0.12.0'
  s.summary          = ''
  s.requires_arc = true
  s.license      = 'MIT'
  s.homepage     = 'n/a'
  s.source       = { :git => "https://github.com/joltup/rn-fetch-blob" }
  s.author       = 'Joltup'
  s.source_files = 'ios/**/*.{h,m}'
  s.platform     = :ios, "8.0"
  s.dependency 'React-Core'
  s.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ios/RNFetchBlob\" \"$(PODS_TARGET_SRCROOT)/ios\"" }
  s.frameworks = 'AssetsLibrary'
end
