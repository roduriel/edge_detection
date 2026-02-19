Pod::Spec.new do |spec|
  spec.name             = 'WeScan'
  spec.version          = '3.0.0'
  spec.summary          = 'Document Scanning Made Easy for iOS'
  spec.description      = 'WeScan makes it easy to add scanning functionalities to your iOS app! It\'s modelled after UIImagePickerController, which makes it a breeze to use.'

  spec.homepage         = 'https://github.com/WeTransfer/WeScan'
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.authors           = {
    'Boris Emorine' => 'boris@wetransfer.com',
    'Antoine van der Lee' => 'antoine@wetransfer.com'
  }
  spec.source           = { :git => 'https://github.com/WeTransfer/WeScan.git', :tag => "#{spec.version}" }
  spec.social_media_url = 'https://twitter.com/WeTransfer'

  spec.swift_version = '5.0'
  spec.ios.deployment_target = '13.0'
  spec.source_files = 'Sources/WeScan/**/*.{h,m,swift}'
  # PNGs from Sources; only es.lproj at pod root to avoid duplicate Localizable.strings in Xcode
  spec.resources = 'Sources/WeScan/**/*.png', 'es.lproj/**/*.strings'
end
