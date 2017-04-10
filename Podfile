# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'HeartAssist' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  
  pod 'Locksmith', '~> 3.0'

  # Use local musli when available
  if File.exist? "../Musli/Musli.podspec"
    pod 'Musli', :path => "../Musli"
  else
    pod 'Musli'
  end

  # Use local Granola when available
  if File.exist? "../Granola/Granola.podspec"
    pod 'Granola', :path => "../Granola"
  end

  target 'HeartAssistTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'HeartAssistUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
