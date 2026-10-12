#!/usr/bin/env ruby
# Add the Garmin bridge (copied by configure_ios_garmin_bridge.py) to the
# Runner target together with the Garmin Connect IQ Mobile SDK Swift package
# and the -ObjC linker flag the SDK requires. Opt-in: only
# .github/workflows/garmin-sim.yml runs it. Idempotent.
require 'xcodeproj'

PACKAGE_URL = 'https://github.com/garmin/connectiq-companion-app-sdk-ios'
# Pinned commit (main, SDK docs 1.8.0). The only release tag is 1.5.0.
PACKAGE_REVISION = 'f0d29ff691d700a132d86205ed9bb091e336c2f7'
PRODUCT = 'ConnectIQ'

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'ios', 'Runner.xcodeproj')
abort("missing generated Xcode project: #{project_path}") unless File.directory?(project_path)
%w[SniperTurkGarminBridge.h SniperTurkGarminBridge.m].each do |name|
  path = File.join(root, 'ios', 'Runner', name)
  abort("missing copied bridge source: #{path}") unless File.file?(path)
end

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |candidate| candidate.name == 'Runner' }
abort('Runner target not found') unless target
runner_group = project.main_group.find_subpath('Runner', false)
abort('Runner group not found') unless runner_group

# Sources.
header = runner_group.files.find { |file| file.path == 'SniperTurkGarminBridge.h' }
runner_group.new_file('SniperTurkGarminBridge.h') unless header
impl = runner_group.files.find { |file| file.path == 'SniperTurkGarminBridge.m' }
impl ||= runner_group.new_file('SniperTurkGarminBridge.m')
unless target.source_build_phase.files_references.include?(impl)
  target.source_build_phase.add_file_reference(impl, true)
end

# Swift package: ConnectIQ (binary xcframework).
package = project.root_object.package_references.find do |ref|
  ref.respond_to?(:repositoryURL) && ref.repositoryURL == PACKAGE_URL
end
unless package
  package = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package.repositoryURL = PACKAGE_URL
  project.root_object.package_references << package
end
package.requirement = { 'kind' => 'revision', 'revision' => PACKAGE_REVISION }

dependency = target.package_product_dependencies.find { |dep| dep.product_name == PRODUCT }
unless dependency
  dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dependency.package = package
  dependency.product_name = PRODUCT
  target.package_product_dependencies << dependency
end
unless target.frameworks_build_phase.files.any? { |file| file.product_ref == dependency }
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = dependency
  target.frameworks_build_phase.files << build_file
end

# The SDK uses Objective-C categories internally.
target.build_configurations.each do |config|
  flags = config.build_settings['OTHER_LDFLAGS'] || ['$(inherited)']
  flags = flags.split(' ') if flags.is_a?(String)
  flags << '-ObjC' unless flags.include?('-ObjC')
  config.build_settings['OTHER_LDFLAGS'] = flags
end

project.save
puts 'Garmin bridge and ConnectIQ package wired into Runner'
