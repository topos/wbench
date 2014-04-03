namespace :wbench do
  require 'sys/proctable'
  include Sys

  desc "run wbench"
  task :run, [:url, :opts] => [:xvfb] do |t,arg| 
    arg.with_defaults(url:'http://gooogle.com', opts:'')
    ENV['PATH'] = "/usr/lib/chromium-browser:#{ENV['PATH']}"
    ENV['LD_LIBRARY_PATH'] = '/usr/lib/chromium-browser/libs'
    ENV['DISPLAY'] = ':99'
    sh "wbench #{arg.url}"
  end

  desc "start xvfb"
  task :xvfb do
    cmd = 'Xvfb :99'
    ps = ProcTable.ps.select{|p| p.cmdline.start_with?(cmd)}
    sh "Xvfb :99 &" if ps.empty?
  end

  desc "install wbench gem and its dependencies"
  task :init do
    sh "bundle install"
    sh "sudo aptitude update -y"
    sh "sudo aptitude install -y chromium-chromedriver xvfb"
  end
end
