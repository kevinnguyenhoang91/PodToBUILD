Pod::Spec.new do |s|

  s.name         = "MMKV"
  s.version      = "1.2.7"
  s.summary      = "MMKV is a cross-platform key-value storage framework developed by WeChat."

  s.description  = <<-DESC
                      The MMKV, for Objective-C.
                      MMKV is an efficient, complete, easy-to-use mobile key-value storage framework used in the WeChat application.
                      It can be a replacement for NSUserDefaults & SQLite.
                   DESC

  s.homepage     = "https://github.com/Tencent/MMKV"
  s.license      = { :type => "BSD 3-Clause", :file => "LICENSE.TXT"}
  s.author       = { "guoling" => "guoling@tencent.com" }

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.9"

  s.source       = { :git => "https://github.com/Tencent/MMKV.git", :tag => "v#{s.version}" }
  s.vendored_frameworks = 'Output/MMKV-Release-iphoneuniversal/MMKV.framework'
  s.libraries    = "z", "c++"
  s.framework    = "CoreFoundation"
  
end

