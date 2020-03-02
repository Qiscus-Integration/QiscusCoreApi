Pod::Spec.new do |s|

s.name         = "QiscusCoreAPI"
s.version      = "0.1.0"
s.summary      = "Qiscus Core API."
s.homepage     = "http://qiscus.com"
s.license      = "MIT"
s.author       = "Qiscus"
s.source       = { :git => "https://github.com/qiscus/QiscusCore-iOS.git", :tag => "#{s.version}" }
s.platform      = :ios, "9.0"
s.ios.vendored_frameworks = 'QiscusCoreAPI.framework'
s.ios.frameworks = ["UIKit", "QuartzCore", "CFNetwork", "Security", "Foundation", "MobileCoreServices", "CoreData"]
s.dependency 'SwiftyJSON'

end
