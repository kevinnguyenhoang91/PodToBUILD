Pod::Spec.new do |s|
  s.name         = 'react-native-webview'
  s.version      = '11.4.3'
  s.summary      = ''
  s.license      = ''

  s.authors      = ''
  s.homepage     = ''
  s.platforms    = { :ios => "9.0", :osx => "10.13" }

  s.source       = { :git => "https://github.com/react-native-webview/react-native-webview.git", :tag => "v#{s.version}" }
  s.source_files  = "apple/**/*.{h,m}"

  s.dependency 'React-Core'
  s.frameworks = 'WebKit'
end
