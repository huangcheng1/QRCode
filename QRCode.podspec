
Pod::Spec.new do |s|
  s.name             = 'QRCode'
  s.version          = '0.1.0'
  s.summary          = '二维码'
  s.description      = <<-DESC
  二维码扫描，创建
  qecode scan or create
                       DESC

  s.homepage         = 'https://github.com/huangcheng1/QRCode'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'huangcheng' => 'huangcheng' }
  s.source           = { :git => 'https://github.com/huangcheng1/QRCode.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.subspec 'Scan' do |camera|
      camera.source_files = 'QRCode/Classes/camera/**/*'
  end
  
  s.subspec 'Create' do |create|
      create.source_files = 'QRCode/Classes/create/**/*'
  end

end
