Pod::Spec.new do |s|
    s.name         = "SSPersistenceController"
    s.version      = "0.0.1"
    s.summary      = "Core Data boilerplate code with multithread approach inspired by Marcus Zarra CoreData Stack (http://martiancraft.com/blog/2015/03/core-data-stack/) and many more it's interpretations."
    s.description  = <<-DESC
                   Core Data boilerplate code with multithread approach inspired by Marcus Zarra CoreData Stack (http://martiancraft.com/blog/2015/03/core-data-stack/) and many more it's interpretations. With very minimal effort we won't block UI even during massive import.
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
