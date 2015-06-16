
#  Be sure to run `pod spec lint SSPersistenceController.podspec' to ensure this is a

Pod::Spec.new do |s|
    s.name         = "SSPersistenceController"
    s.version      = "0.0.1"
    s.summary      = "Core Data boiler plate code"
    s.description  = <<-DESC
                   Core Data boiler plate code - todo
                   DESC
    s.homepage     = "https://github.com/ssuchanowski/SSPersistenceController"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author    = {"Sebastian Suchanowski" => "sebastian@synappse.pl"}
    s.social_media_url   = "http://twitter.com/ssuchanowski"
    s.platform     = :ios, "8.0"
    s.ios.deployment_target = "8.0"
    s.source       = { :git => "https://github.com/ssuchanowski/SSPersistenceController.git", :tag => s.version.to_s }
    # s.source_files  = "SSPersistenceController/**/*.{h,m}"
    s.source_files  = "*.{h,m}"
    s.frameworks = 'CoreData'
    s.requires_arc = true
    s.dependency "KZAsserts"
end
