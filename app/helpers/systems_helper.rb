# -*- encoding: utf-8 -*-

One.helpers do
  def get_sysinfo
    os = `uname`.sub("\n", '')
    if os == 'Linux' 
      diskinfo = `df | awk '{print $2,$4,$5}'`
      diskinfo = diskinfo.split("\n")[1]
      diskinfo = diskinfo.split(' ')

      disk_total = diskinfo[0].to_f
      disk_free  = diskinfo[1].to_f
      disk_used  = disk_total - disk_free
      disk_perc  = diskinfo[2].sub('%','').round

      meminfo   = `cat /proc/meminfo | grep Mem | awk '{print $2}'`

      mem_total = Float(meminfo.split("\n").first)
      mem_free  = Float(meminfo.split("\n").last)
      mem_used  = mem_total - mem_free
      mem_perc  = ((100/mem_total)*mem_used).round
   
      cpu_perc = `vmstat | awk '{print $13}'`.split("\n").last.round
   
      uptime = `uptime`.chomp.to_s.gsub( /up|days|load average:/, 'up' => '已运行', 'days' => '天', 'load average:' => '系统负荷：')

      return { 
        disk: { total: (disk_total / 1024 / 1024).round(2), free: (disk_free / 1024 / 1024).round(2), used: (disk_used / 1024 / 1024).round(2), perc: disk_perc}, 
        mem:  { total: (mem_total / 1024).round(2),         free: (mem_free / 1024).round(2),         used: (mem_used / 1024).round(2),         perc: mem_perc}, 
        cpu:  { perc: cpu_perc }, 
        uptime: uptime 
      }
    end
    nil
  end
end
