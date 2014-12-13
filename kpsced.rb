#!/usr/bin/ruby

# KICAD POSTSCRIPT COLOR EDITOR
# -fruchti 2014

require 'optparse'
require 'fileutils'

$configfilename = "#{Dir.home}/.kpsced"
$eeschemapath = "#{Dir.home}/.eeschema"

def hextops(color)
    if !(color =~ /^[0-9a-f]{6}$/i)
        puts color + " is not a valid color"
        exit 1
    end
    r = "%0.3f" % (color.gsub(/^([0-9a-f]{2})[0-9a-f]{4}$/i, '\1').to_i(16) / 255.0)
    g = "%0.3f" % (color.gsub(/^[0-9a-f]{2}([0-9a-f]{2})[0-9a-f]{2}$/i, '\1').to_i(16) / 255.0)
    b = "%0.3f" % (color.gsub(/^[0-9a-f]{4}([0-9a-f]{2})$/i, '\1').to_i(16) / 255.0)
    return r + " " + g + " " + b + " setrgbcolor"
end

def parseeeschemaconfig
    eeschemafile = File.open($eeschemapath, 'r')
    config = eeschemafile.read()
    eeschemafile.close()

    outputfile = File.open($configfilename, 'w')

    config = config.scan(/Color[A-Za-z]+Ex=[A-Za-z]+ ?[0-9]*/).join("\n")
    config.gsub!(/Black/, '0 0 0')
    config.gsub!(/Gray 1/, '0.282 0.282 0.282')
    config.gsub!(/Gray 2/, '0.518 0.518 0.518')
    config.gsub!(/Gray 3/, '0.761 0.761 0.761')
    config.gsub!(/White/, '1 1 1')
    config.gsub!(/L.Yellow/, '1 1 0.761')
    config.gsub!(/Blue 1/, '0 0 0.282')
    config.gsub!(/Green 1/, '0 0.282 0')
    config.gsub!(/Cyan 1/, '0 0.282 0.282')
    config.gsub!(/Red 1/, '0.282 0 0')
    config.gsub!(/Magenta 1/, '0.282 0 0.282')
    config.gsub!(/Brown 1/, '0.282 0.282 0')
    config.gsub!(/Blue 2/, '0 0 0.518')
    config.gsub!(/Green 2/, '0 0.518 0')
    config.gsub!(/Cyan 2/, '0 0.518 0.518')
    config.gsub!(/Red 2/, '0.518 0 0')
    config.gsub!(/Magenta 2/, '0.518 0 0.518')
    config.gsub!(/Brown 2/, '0.518 0.518 0')
    config.gsub!(/Blue 3/, '0 0 0.761')
    config.gsub!(/Green 3/, '0 0.761 0')
    config.gsub!(/Cyan 3/, '0 0.761 0.761')
    config.gsub!(/Red 3/, '0.761 0 0')
    config.gsub!(/Magenta 3/, '0.761 0 0.761')
    config.gsub!(/Yellow 3/, '0.761 0.761 0')
    config.gsub!(/Blue 4/, '0 0 1')
    config.gsub!(/Green 4/, '0 1 0')
    config.gsub!(/Cyan 4/, '0 1 1')
    config.gsub!(/Red 4/, '1 0 0')
    config.gsub!(/Magenta 4/, '1 0 1')
    config.gsub!(/Yellow 4/, '1 1 0')

    outputfile.puts(config[/ColorWireEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorBusEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorConnEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorLLabelEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorHLabelEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorGLabelEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorPinNumEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorPinNameEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorFieldEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorReferenceEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorValueEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorNoteEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorBodyEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorBodyBgEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorNetNameEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorPinEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorSheetEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorSheetFileNameEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorSheetNameEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorSheetLabelEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorNoConnectEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorErcWEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorErcEEx=([0-9. ]+)/, 1])
    outputfile.puts(config[/ColorGridEx=([0-9. ]+)/, 1])

    outputfile.close()
end

if !File.exists?($configfilename)
    parseeeschemaconfig()
end

eecfg = IO.readlines($configfilename)

colors = Array.new(24)

options = {}

optparse = OptionParser.new do |opts|
    opts.banner = "Usage: " + File.basename(__FILE__) + " [options] FILE"

    options[:outputfile] = nil
    opts.on('-o', '--output FILE', 'Write to FILE') do |file|
        options[:outputfile] = file
    end

    opts.on('-j', '--reconfig', 'Re-parse Eeschema configuration file') do
        parseeeschemaconfig()
    end

    opts.on('-w', '--wirecolor COLOR', 'Set wire color') do |color|
        colors[0] = color
    end

    opts.on('-b', '--buscolor COLOR', 'Set bus color') do |color|
        colors[1] = color
    end

    opts.on('-c', '--conncolor COLOR', 'Set connection dot color') do |color|
        colors[2] = color
    end

    opts.on('-l', '--llabelcolor COLOR', 'Set local label color') do |color|
        colors[3] = color
    end

    opts.on('-h', '--hlabelcolor COLOR', 'Set hierarchical label color') do |color|
        colors[4] = color
    end

    opts.on('-g', '--glabelcolor COLOR', 'Set global label color') do |color|
        colors[5] = color
    end

    opts.on('-n', '--pinnumcolor COLOR', 'Set pin number color') do |color|
        colors[6] = color
    end

    opts.on('-p', '--pinnamecolor COLOR', 'Set pin name color') do |color|
        colors[7] = color
    end

    opts.on('-f', '--fieldcolor COLOR', 'Set field color') do |color|
        colors[8] = color
    end

    opts.on('-r', '--refcolor COLOR', 'Set reference color') do |color|
        colors[9] = color
    end

    opts.on('-v', '--valuecolor COLOR', 'Set value color') do |color|
        colors[10] = color
    end

    opts.on('-t', '--notecolor COLOR', 'Set note color') do |color|
        colors[11] = color
    end

    opts.on('-d', '--bodycolor COLOR', 'Set body color') do |color|
        colors[12] = color
    end

    opts.on('-y', '--bodybgcolor COLOR', 'Set body background color') do |color|
        colors[13] = color
    end

    opts.on('-e', '--netnamecolor COLOR', 'Set net name color') do |color|
        colors[14] = color
    end

    opts.on('-i', '--pincolor COLOR', 'Set pin color') do |color|
        colors[15] = color
    end

    opts.on('-s', '--sheetcolor COLOR', 'Set sheet color') do |color|
        colors[16] = color
    end

    opts.on('-x', '--sheetfilenamecolor COLOR', 'Set sheet file name color') do |color|
        colors[17] = color
    end

    opts.on('-u', '--sheetnamecolor COLOR', 'Set sheet name color') do |color|
        colors[18] = color
    end

    opts.on('-a', '--sheetlabelcolor COLOR', 'Set sheet label color') do |color|
        colors[19] = color
    end

    opts.on('-q', '--noconnectcolor COLOR', 'Set no connection mark color') do |color|
        colors[20] = color
    end

    opts.on(nil, '--ercwcolor COLOR', 'Set ERC warning color') do |color|
        colors[21] = color
    end

    opts.on(nil, '--ercecolor COLOR', 'Set ERC error color') do |color|
        colors[22] = color
    end

    opts.on(nil, '--gridcolor COLOR', 'Set grid color') do |color|
        colors[23] = color
    end

    options[:titlecolor] = nil
    opts.on('-z', '--titlecolor COLOR', 'Set schematic title color to hex value') do |color|
        options[:titlecolor] = color
    end

    opts.on('-?', '--help', 'Help screen') do
        puts opts
        exit
    end
end

optparse.parse!

ARGV.each do |a|
    if options[:outputfile] == nil 
        options[:outputfile] = a
    end
    ifile = File.open(a, 'r')
    
    tfilename = options[:outputfile]
    while File.exists?(tfilename + ".tmp") do
        tfilename += "_"
    end
    tfilename += ".tmp"

    tfile = File.open(tfilename, 'w')

    ifile.each do |line|
        if options[:titlecolor] != nil
            line.sub!("0.518 0 0 setrgbcolor", hextops(options[:titlecolor]))
        end
        for i in 0..23
            if colors[i] != nil
                line.sub!(eecfg[i].strip + " setrgbcolor", hextops(colors[i]))
            end
        end
        tfile.puts(line)
    end

    ifile.close()
    tfile.close()

    FileUtils.mv(tfilename, options[:outputfile])
end

