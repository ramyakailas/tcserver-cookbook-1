Ohai.plugin(:Tcserver) do
  provides 'warhotel'
  depends 'languages'


  def create_objects
    warhotel Mash.new
  end


  def get_java_info
    so = shell_out("java -version")
    if so.exitstatus == 0
      so.stderr.split(/\r?\n/).each do |line|
        case line
        when /java version \"([0-9\.\_]+)\"/
          warhotel[:java_version] = $1
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
   command=Mixlib::ShellOut.new("ls -l --time-style='+%d/%m/%Y' #{filepath} | awk '{print $6}'").run_command.stdout.strip
   files[warname] = {
     'version' => command,
     'filepath' => filepath,
     'warname' => warname
   }
  end
  files
end


def tc_runtime_status
  Mixlib::ShellOut.new("/opt/vmware/vfabric-tc-server-standard/myserver/bin/tcruntime-ctl.sh status", user: 'root').run_command.stdout
end

def get_tc_server_info
  instances = {}
  tc_runtime_status.each_line do |line|
  key, value = line.split(':',2)
  formatted_key = key.strip.downcase.gsub(/\s/,'_')
  instances[formatted_key] = value.strip
  instances[:wars] = get_war_status
  #instances[:wars] = instances.merge(files) {|key, old, new| old}
  end
warhotel['instances'] = instances

end

  collect_data(:default) do
    create_objects
    so = shell_out('uname -r')
    warhotel[:rhelversion] = so.stdout.split($/)[0]
    get_java_info
    get_tc_server_info
    get_war_status
    end
end
