Ohai.plugin(:Tcserver) do
  provides 'warhotel'
  depends 'languages'
  depends 'platform_family', 'platform'
  depends 'os', 'os_version'

  def create_objects
    warhotel Mash.new
  end

  def get_java_info
    so = shell_out('java -version')
    if so.exitstatus == 0
      so.stderr.split(/\r?\n/).each do |line|
        case line
        when /java version \"([0-9\.\_]+)\"/
          warhotel[:java_version] = $1
        when /^(.+Runtime Environment.*) \((build )?(.+)\)$/
          warhotel[:runtime] = { "name" => $1, "build" => $3 }
        when /^(.+ (Client|Server) VM) \(build (.+)\)$/
          warhotel[:hotspot] = { "name" => $1, "build" => $3 }
        end
      end
    end
  end

def get_war_status
 # file = ['/opt/vmware/vfabric-tc-server-standard/myserver/webapps/CrunchifyTutorial-0.0.1-SNAPSHOT.war']
  file = []
  cmd = Mixlib::ShellOut.new("find /opt/vmware -name *.war").run_command.stdout.split("\n")
  file = cmd
  files = {}
  file.each do |filepath|
  warname = File.basename(filepath)
  command = Mixlib::ShellOut.new("ls -l --time-style='+%d/%m/%Y' #{filepath} | awk '{print $6}'").run_command.stdout.strip
  files[warname] = {
  'version' => command,
  'filepath' => filepath,
  'warname' => warname
   }
  end
  files
end

def tc_runtime_status
  Mixlib::ShellOut.new("/opt/vmware/vfabric-tc-server-standard/test-instance1/bin/tcruntime-ctl.sh status", user: 'root').run_command.stdout
end
# 
# def tc_runtime_status
#   find = Mixlib::ShellOut.new("/opt/vmware/vfabric-tc-server-standard/tcruntime-instance.sh list -i /opt/vmware/vfabric-tc-server-standard| tail -n +3", user: 'root').run_command.stdout
#    puts find.stdout
# end

def get_tc_server_info
  instances = {}
    tc_runtime_status.each_line do |line|
    key, value = line.split(':',2)
    formatted_key = key.strip.downcase.gsub(/\s/,'_')
    instances[formatted_key] = value.strip
    instances[:wars] = get_war_status
    end
    warhotel['instances'] = instances
end

  collect_data(:default) do
    create_objects
    # so = shell_out('uname -r')
    # warhotel[:rhelversion] = so.stdout.split($/)[0]
    warhotel[:platform] = platform
    warhotel[:platform_version] = platform_version
    warhotel[:platform_family] = platform_family
    tc_runtime_status
    get_java_info
    get_tc_server_info
    get_war_status
  end
end
