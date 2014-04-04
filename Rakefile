require 'smart_colored/extend'
PROJ_HOME = File.expand_path File.dirname(__FILE__)
Dir.glob("#{PROJ_HOME}/lib/task/*.rake"){|p| import p}

desc "install hacked version of /usr/lib/ruby/1.9.1/json/common.rb".red
task :install_common_rb do
  if File.exists?('/usr/lib/ruby/1.9.1/json/common.rb.orig')
    puts "noop: hacked version already installed"
  else
    sh "sudo mv -f /usr/lib/ruby/1.9.1/json/common.rb /usr/lib/ruby/1.9.1/json/common.rb.orig"
    sh "sudo cp #{PROJ_HOME}/src/common.rb /usr/lib/ruby/1.9.1/json/common.rb"
  end
end
