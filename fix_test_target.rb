require 'xcodeproj'
project_path = '/Users/andrew/development/PhotoRouteApp/PhotoRoute.xcodeproj'
project = Xcodeproj::Project.open(project_path)
test_target = project.targets.find { |t| t.name == 'PhotoRouteTests' }
test_target.build_configurations.each do |config|
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
end
project.save
