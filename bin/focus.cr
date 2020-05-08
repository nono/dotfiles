def window_number
  ARGV.first?.try(&.to_i) || 0
end

def current_desktop
  `wmctrl -d`.each_line do |line|
    return $1.to_i if /^(\d+)\s+\*\s/ =~ line
  end
  0
end

record Window, id : String, desktop : Int32, x : Int32, y : Int32

def windows
  `wmctrl -l -G`.lines.map do |line|
    next unless /^(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+/ =~ line
    Window.new id: $1, desktop: $2.to_i, x: $3.to_i, y: $4.to_i
  end.compact
end

def windows_on(desktop)
  windows.select { |w| w.desktop == desktop }.sort_by { |w| [w.x, w.y] }
end

def activate(window)
  Process.run "xdotool", ["windowactivate", window.id]
end

activate windows_on(current_desktop)[window_number]
