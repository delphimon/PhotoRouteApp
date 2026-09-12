require 'xcodeproj'
project_path = '/Users/andrew/development/PhotoRouteApp/PhotoRoute.xcodeproj'
project = Xcodeproj::Project.open(project_path)
test_target = project.targets.find { |t| t.name == 'PhotoRouteTests' }
main_target = project.targets.find { |t| t.name == 'PhotoRoute' }

# Add Analysis to Main
Dir.glob('/Users/andrew/development/PhotoRouteApp/PhotoRoute/**/*.swift').each do |file|
  path = file.gsub('/Users/andrew/development/PhotoRouteApp/', '')
  unless main_target.source_build_phase.files_references.any? { |ref| ref.real_path.to_s == file }
    group = project.main_group
    path.split('/')[0...-1].each do |folder|
      group = group.children.find { |c| c.display_name == folder || c.path == folder } || group.new_group(folder, folder)
    end
    file_ref = group.new_file(file)
    main_target.add_file_references([file_ref])
    puts "Added #{file} to Main"
  end
end

# Add Tests to Test
Dir.glob('/Users/andrew/development/PhotoRouteApp/PhotoRouteTests/**/*.swift').each do |file|
  path = file.gsub('/Users/andrew/development/PhotoRouteApp/', '')
  unless test_target.source_build_phase.files_references.any? { |ref| ref.real_path.to_s == file }
    group = project.main_group
    path.split('/')[0...-1].each do |folder|
      group = group.children.find { |c| c.display_name == folder || c.path == folder } || group.new_group(folder, folder)
    end
    file_ref = group.new_file(file)
    test_target.add_file_references([file_ref])
    puts "Added #{file} to Test"
  end
end

project.save
