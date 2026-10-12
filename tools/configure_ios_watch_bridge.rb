#!/usr/bin/env ruby
# Add the watch bridge source (copied by configure_ios_watch_bridge.py) to the
# Runner target. Opt-in: only .github/workflows/watch-sim.yml runs it.
require 'xcodeproj'

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'ios', 'Runner.xcodeproj')
source = File.join(root, 'ios', 'Runner', 'SniperTurkWatchBridge.swift')

abort("missing generated Xcode project: #{project_path}") unless File.directory?(project_path)
abort("missing copied bridge source: #{source}") unless File.file?(source)

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |candidate| candidate.name == 'Runner' }
abort('Runner target not found') unless target
runner_group = project.main_group.find_subpath('Runner', false)
abort('Runner group not found') unless runner_group

reference = runner_group.files.find { |file| file.path == 'SniperTurkWatchBridge.swift' }
reference ||= runner_group.new_file('SniperTurkWatchBridge.swift')
unless target.source_build_phase.files_references.include?(reference)
  target.source_build_phase.add_file_reference(reference, true)
end
project.save
puts 'Watch bridge wired into Runner sources'
