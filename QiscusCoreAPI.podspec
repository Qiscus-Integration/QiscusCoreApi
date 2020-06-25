Pod::Spec.new do |s|

s.name         = "QiscusCoreAPI"
s.version      = "0.3.1"
s.summary      = "Qiscus Core API."
s.homepage     = "http://qiscus.com"
s.license      = "MIT"
s.author       = "Qiscus"
s.source       = { :git => "https://github.com/Qiscus-Integration/QiscusCoreApi.git", :tag => "#{s.version}" }
s.platform      = :ios, "10.0"
s.source_files  = "QiscusCoreAPI", "Source/QiscusCoreAPI/**/*.{h,m,swift}"
s.resources = "Source/QiscusCoreAPI/**/*.xcassets"
s.resource_bundles = {
    'QiscusCoreAPI' => ['Source/QiscusCoreAPI/**/*.{lproj,xib,xcassets,imageset,png}']
}
s.ios.frameworks = ["UIKit", "QuartzCore", "CFNetwork", "Security", "Foundation", "MobileCoreServices", "CoreData"]
s.dependency 'SwiftyJSON'

end
