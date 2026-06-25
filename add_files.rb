require 'xcodeproj'

project_path = 'SuperSelf.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Add ExchangeRateService.swift to Services group
services_group = project.main_group.find_subpath('SuperSelf/Services', true)
service_file_ref = services_group.new_reference('ExchangeRateService.swift')
target.source_build_phase.add_file_reference(service_file_ref)

# Add ExchangeRatePage.swift to Profile group
profile_group = project.main_group.find_subpath('SuperSelf/Features/Profile', true)
page_file_ref = profile_group.new_reference('ExchangeRatePage.swift')
target.source_build_phase.add_file_reference(page_file_ref)

project.save
puts "Added files to Xcode project successfully."
