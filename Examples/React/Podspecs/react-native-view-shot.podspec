Pod::Spec.new do |s|
  s.name         = "react-native-view-shot"
  s.version      = "3.0.2"
  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/gre/react-native-view-shot.git", :tag => "v#{s.version}" }
  s.source_files  = "ios/**/*.{h,m}"

  s.dependency 'React-Core'
end

