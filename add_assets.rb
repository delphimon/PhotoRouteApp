require 'xcodeproj'
project_path = '/Users/andrew/development/PhotoRouteApp/PhotoRoute.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first
main_group = project.main_group.groups.find { |g| g.display_name == 'PhotoRoute' }
unless main_group.files.any? { |f| f.path == 'Assets.xcassets' }
  file_ref = main_group.new_file('Assets.xcassets')
  target.add_resources([file_ref])
end
project.save
puts "Added Assets.xcassets"
