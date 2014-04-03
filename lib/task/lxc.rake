namespace :lxc do
  desc "start an lx container"
  task :start, [:name,:state] do |t,arg|
    raise "error: lxc \"name\" is required" if arg.name.nil?
    3.times do
      begin
        sh "sudo lxc-start -d -n #{arg.name}"
      rescue
        sleep 3
        retry
      end
      break
    end
    sh "sudo lxc-wait -n #{arg.name} -s #{arg.state}" unless arg.state.nil?
  end

  desc "stop an lx container gracefully or immediately"
  task :stop, [:name] do |t,arg|
    raise "error: lxc \"name\" is required" if arg.name.nil?
    arg.with_defaults(stop:false)
    unless arg.stop
      gracetime = 10
      sh "sudo lxc-stop --shutdown -t #{gracetime} -n #{arg.name}"
    else
      sh "sudo lxc-stop -n #{arg.name}"
    end
  end

  desc "stop any lx container in a running state"
  task :startall, [:match] do |t,arg|
    arg.with_defaults(match: nil)
    match = arg.match
    `sudo lxc-ls --stopped`.strip.split(/\s+/).each do |name|
      if match.nil? || name.start_with?(match)
        task('lxc:start').reenable
        task('lxc:start').invoke(name)
      end
    end
  end

  desc "start any lx container in a running state"
  task :stopall, [:match] do |t,arg|
    arg.with_defaults(match: nil)
    match = arg.match
    `sudo lxc-ls --running`.strip.split(/\s+/).each do |name|
      if match.nil? || name.start_with?(match)
        task('lxc:stop').reenable
        task('lxc:stop').invoke(name)
      end
    end
  end

  desc "detroy any lx container in a stopped state"
  task :destroyall, [:match] do |t,arg|
    arg.with_defaults(match: nil)
    match = arg.match
    `sudo lxc-ls --stopped`.strip.split(/\s+/).each do |name|
      if match.nil? || name.start_with?(match)
        task('lxc:destroy').reenable
        task('lxc:destroy').invoke(name)
      end
    end
  end

  desc "a synonym for lxc:attach"
  task :exec, [:name,:cmd] => :attach

  desc "exec a command in a container"
  task :attach, [:name,:cmd] do |t,arg|
    puts "#{arg.cmd}".red
    raise "error: undefined arg.name" if arg.name.nil?
    if arg.cmd.nil? || arg.cmd == ""
      sh "sudo lxc-attach -n #{arg.name}"
    else
      sh "sudo lxc-attach -n #{arg.name} -- #{arg.cmd}"
    end
  end

  desc "install packages".green
  task :install, [:name,:packages] do |t,arg|
    raise "error: lxc \"name\" is required" if arg.name.nil?
    task("lxc:exec").reenable
    task("lxc:exec").invoke(arg.name,'sudo apt-get update -y')
    arg.packages.split(/\s+/).map{|pkg|"sudo apt-get install -y #{pkg}"}.each do |cmd|
      task("lxc:exec").reenable
      task("lxc:exec").invoke(arg.name,cmd)
    end
  end

  desc "login"
  task :login, [:name] do |t,arg|
    raise "error: lxc \"name\" is required" if arg.name.nil?
    sh "sudo lxc-console -n #{arg.name}"
  end

  desc "list"
  task :ls => :list
  task :list do
    sh "sudo lxc-ls --fancy"
  end

  desc "lxc ps"
  task :ps, [:opt] do |t,arg|
    if arg.option.nil?
      sh "sudo lxc-ps -n plain"
    else
      sh "sudo lxc-ps -n plain -- #{arg.option}"
    end
  end

  desc "ssh"
  task :ssh, [:name,:cmd] do |t,arg|
    raise "error: lxc \"name\" is required" if arg.name.nil?
    if arg.cmd.nil?
      sh "ssh #{lxc2ip(arg.name)}"
    else
      sh "ssh #{lxc2ip(arg.name)} '#{arg.cmd}'"
    end
  end

  desc "lxc2 name to ip addr."
  task :ip, [:name] do |t,arg|
    raise "error: lxc \"name\" is required" if arg.name.nil?
    puts "ip=#{lxc2ip(arg.name)}".green
  end

  desc "copy ~ubunut/.bashrd"
  task :dotsh, [:name] do |t,arg|
    raise "error: name undefined".red if arg.name.nil?
    lxcs = if ":all" == arg.name
             `sudo lxc-ls -1`.lines.each.map{|l|l.strip}
           else
             [arg.name]
           end
    lxcs.each do |name|
      puts "lxc=#{name.red}"
      sh "sudo cp #{TASK_DIR}/bashrc -p /var/lib/lxc/#{name}/rootfs/home/ubuntu/.bashrc"
    end
  end

  task :dotssh, [:name] do |t,arg|
    raise "error: name undefined".red if arg.name.nil?
    lxcs = if ":all" == arg.name
             `sudo lxc-ls -1`.lines.each.map{|l|l.strip}
           else
             [arg.name]
           end
    lxcs.each do |name|
      puts "lxc=#{name.red}"
      FileList["/home/#{ENV['LOGNAME']}/.ssh/*.pub"].each.with_index do |pk,i|
        if i == 0
          sh "cat #{pk} > /var/tmp/authorized_keys"
        else
          sh "cat #{pk} >> /var/tmp/authorized_keys"
        end
      end
      sh "sudo mkdir -p /var/lib/lxc/#{name}/rootfs/home/ubuntu/.ssh"
      sh "sudo cp /var/tmp/authorized_keys /var/lib/lxc/#{name}/rootfs/home/ubuntu/.ssh/."
      sh "sudo chmod -R go-rwx /var/lib/lxc/#{name}/rootfs/home/ubuntu/.ssh"
      task('lxc:exec').reenable
      task('lxc:exec').invoke(name,'chown -R ubuntu /home/ubuntu/.ssh')
    end
  end

  desc "destroy lx container"
  task :destroy, [:name,:force] do |t,arg|
    raise "error: lxc \"name\" is required" if arg.name.nil?
    unless arg.force.nil?
      sh "rake lxc:stop[#{arg.name}]"
    end
    sh "sudo lxc-destroy -n #{arg.name}"
  end

  desc "make a linux container--defaults:linux/<current release>"
  task :make, [:name,:template,:release] do |t,arg|
    arg.with_defaults(name: "linux",template: "ubuntu",release: nil)
    cmd = [] << "lxc-create -t ubuntu -n #{arg.name}"
    cmd << "-- -r #{arg.release}" unless arg.release.nil?
    sh "sudo #{cmd.join(' ')}"
    sh "sudo lxc-wait -n #{arg.name} -s STOPPED" unless arg.state.nil?
    sh "rake lxc:start[#{arg.name}]"
    sh "sudo lxc-wait -n #{arg.name} -s RUNNING" unless arg.state.nil?
    puts "waiting for network... sleeping 10 s.".yellow
    sleep 10
    sh "rake lxc:install[#{arg.name},'lxc rsync aptitude']"
    sh "rake lxc:sudo_access[#{arg.name},ubuntu]"
    sh "rake lxc:dotsh[#{arg.name}]"
    sh "rake lxc:dotssh[#{arg.name}]"
  end

  desc "make a linux container for development"
  task :make_dev, [:name,:template,:release] => [:make] do |t,arg|
    sh "rake lxc:sync[#{arg.name}]"
    sh "rake lxc:ssh[#{arg.name},'cd hray && make -f lib/dev.make']"
  end

  desc "give sudo access to a user on an lxc name"
  task :sudo_access, [:name,:user] do |t,arg|
    raise "error: :name and :user are undefined" if arg.name.nil? || arg.user.nil?
    task("lxc:exec").invoke(arg.name,"/bin/sh -c \"echo '#{arg.user}  ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/#{arg.user}\ && chmod 0440 /etc/sudoers.d/#{arg.user}\"")
  end

  desc "initialize/install lxc".green
  task :init => [:install_lxc,:network_config]

  desc "configure outbound IP traffic from a container"
  task :network_config do
    # ! may not be needed anymore
    # dotdir = File.expand_path(File.dirname(__FILE__))
    # if File.exists?("/etc/lxc/default.conf") && !File.exists?("/etc/lxc/default.conf.orig")
    #   Dir.chdir("/etc/lxc") do
    #     sh "sudo mv -f default.conf default.conf.orig"
    #   end
    # end
    # sh "sudo cp #{dotdir}/lxc_default.conf /etc/lxc/default.conf"
  end

  # @todo: automate
  desc "configure bridge network on primary host".red
  task :bridge_network do
    puts "- append the following to /etc/network/interfaces:"
    puts "auto lxcbr0"
    puts "iface br0 inet static"
    puts "    bridge_ports eth0"
    puts "    bridge_stp off"
    puts "    bridge_fd 0"
    puts "    bridge_maxwait 0"
    puts "- and comment out \"eth0\" fragment"
  end

  def lxc2ip(name)
    i = 3
    ip = `sudo lxc-ls --fancy|egrep '^#{name}\s+'|awk '{print $3}'`.strip
    while ip =~ /[^,]+,$/
      ip = `sudo lxc-ls --fancy|egrep '^#{name}\s+'|awk '{print $#{i}}'`.strip
      i += 1
    end
    ip
  end

  desc "rsync PROJ_HOME to lxc"
  task :sync, [:name] do |t,arg|
    sh "rake lxc:exec[#{arg.name},'sudo apt-get install -y #{default_packages}']"
    sh "rsync -avx --exclude .git --delete #{PROJ_HOME} ubuntu@#{lxc2ip(arg.name)}:/home/ubuntu/"
    sh "rake lxc:exec[#{arg.name},'mkdir  -p /opt']"
    sh "rake lxc:exec[#{arg.name},'chown -R ubuntu /opt']"
    sh "rsync -avx --exclude .git --delete /opt/ ubuntu@#{lxc2ip(arg.name)}:/opt/"
  end

  desc "install lxc"
  task :install_lxc do
    sh "sudo aptitude update -y"
    sh "sudo aptitude install -y lxc"
  end

  def default_packages 
    'lxc rsync ruby2.0 ruby2.0-dev git-core curl zlib1g-dev build-essential libssl-dev libgmp-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev'
  end
end
