#!/usr/bin/env ruby
# Wire the app-owned privacy manifest into the generated Runner target.
# Requires the xcodeproj gem supplied with CocoaPods on the macOS CI host.
require 'fileutils'
require 'xcodeproj'

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'ios', 'Runner.xcodeproj')
template = File.join(root, 'release', 'ios', 'PrivacyInfo.xcprivacy')
destination = File.join(root, 'ios', 'Runner', 'PrivacyInfo.xcprivacy')

abort("missing canonical privacy manifest: #{template}") unless File.file?(template)
abort("missing generated Xcode project: #{project_path}") unless File.directory?(project_path)

FileUtils.cp(template, destination)
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |candidate| candidate.name == 'Runner' }
abort('Runner target not found') unless target
runner_group = project.main_group.find_subpath('Runner', false)
abort('Runner group not found') unless runner_group

reference = runner_group.files.find { |file| file.path == 'PrivacyInfo.xcprivacy' }
reference ||= runner_group.new_file('PrivacyInfo.xcprivacy')
unless target.resources_build_phase.files_references.include?(reference)
  target.resources_build_phase.add_file_reference(reference, true)
end
project.save
puts 'Runner privacy manifest copied and wired into Copy Bundle Resources'
