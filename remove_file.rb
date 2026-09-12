require 'xcodeproj'
project_path = '/Users/andrew/development/PhotoRouteApp/PhotoRoute.xcodeproj'
project = Xcodeproj::Project.open(project_path)
main_target = project.targets.find { |t| t.name == 'PhotoRoute' }

ref = main_target.source_build_phase.files_references.find { |r| r.path =~ /Models\/TripAnalysis\.swift/ }
if ref
  main_target.source_build_phase.remove_file_reference(ref)
  ref.remove_from_project
  puts "Removed from pbxproj"
end
project.save
