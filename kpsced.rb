#!/usr/bin/ruby

# KICAD POSTSCRIPT COLOR EDITOR

require 'optparse'
require 'fileutils'
require 'yaml'

#  Default path to the Eeschema configuration file
$eeschemaconfigpath = "#{Dir.home}/.config/kicad/eeschema"

# Thenewcolors used by Eeschema
$colordefinitions = {
    'Black' => '0 0 0',
    'Gray 1' => '0.282 0.282 0.282',
    'Gray 2' => '0.518 0.518 0.518',
    'Gray 3' => '0.761 0.761 0.761',
    'White' => '1 1 1',
    'L.Yellow' => '1 1 0.761',
    'Blue 1' => '0 0 0.282',
    'Green 1' => '0 0.282 0',
    'Cyan 1' => '0 0.282 0.282',
    'Red 1' => '0.282 0 0',
    'Magenta 1' => '0.282 0 0.282',
    'Brown 1' => '0.282 0.282 0',
    'Blue 2' => '0 0 0.518',
    'Green 2' => '0 0.518 0',
    'Cyan 2' => '0 0.518 0.518',
    'Red 2' => '0.518 0 0',
    'Magenta 2' => '0.518 0 0.518',
    'Brown 2' => '0.518 0.518 0',
    'Blue 3' => '0 0 0.761',
    'Green 3' => '0 0.761 0',
    'Cyan 3' => '0 0.761 0.761',
    'Red 3' => '0.761 0 0',
    'Magenta 3' => '0.761 0 0.761',
    'Yellow 3' => '0.761 0.761 0',
    'Blue 4' => '0 0 1',
    'Green 4' => '0 1 0',
    'Cyan 4' => '0 1 1',
    'Red 4' => '1 0 0',
    'Magenta 4' => '1 0 1',
    'Yellow 4' => '1 1 0'}

# Checks and unifies color syntax
def checkcolor(color)
    if !(color =~ /^#?[0-9a-f]{6}$/i)
        return nil
    end
    return color.gsub(/^#?([0-9a-fA-F]{6})$/i, '#\1').downcase()
end


# Converts a hexadecimal color (like #ffffff) into the notation used by postscript
def hextops(color)
    r = "%0.3f" % (color.gsub(/^#?([0-9a-fA-F]{2})[0-9a-fA-F]{4}$/i, '\1').to_i(16) / 255.0)
    g = "%0.3f" % (color.gsub(/^#?[0-9a-fA-F]{2}([0-9a-fA-F]{2})[0-9a-f]{2}$/i, '\1').to_i(16) / 255.0)
    b = "%0.3f" % (color.gsub(/^#?[0-9a-fA-F]{4}([0-9a-fA-F]{2})$/i, '\1').to_i(16) / 255.0)
    return r + ' ' + g + ' ' + b + ' setrgbcolor'
end

# This function parses the Eeschema configuration and extracts the color settings
def parseeeschemaconfig(path)
    # Open file and extract lines that contain color settings into an array
    eeschemafile = File.open(path, 'r')
    configlines = eeschemafile.read().scan(/Color[A-Za-z]+Ex=[A-Za-z.]+ ?[0-9]*/)
    eeschemafile.close()

    # Parse each color setting
    config = Hash.new()
    configlines.each do |configline|
        color = configline.split('=')
        config[color[0]] = color[1]
    end

    return config
end

# Looks fornewcolors appearing more than one time
def showdoubles(config)
    # Group color settings by color
    grouped = config.keys.group_by { |key| config[key] }
    grouped.reject! { |key, group| group.count < 2 }
    if grouped.count == 0
        puts 'No color is used more than one time. Every setting can be made independently.'
    else
        puts 'The followingnewcolors are used repeatedly and cannot be changed independently:'
        grouped.each do |group|
            puts '"' + group.shift + '" is used for:'
            group.flatten!
            group.each do |setting|
                puts ' ' + setting
            end
        end
    end
end

options = Hash.new()
newcolors = Hash.new()

optparse = OptionParser.new do |opts|
    opts.banner = 'Usage: ' + File.basename(__FILE__) + ' [options] FILE'

    options['OutputFile'] = nil
    opts.on('-o', '--output FILE', 'Write to FILE') do |file|
        options['OutputFile'] = file
    end

    options['EeschemaConfigFile'] = $eeschemaconfigpath
    opts.on('-k', '--config FILE', 'Use different Eeschema config file') do |file|
        options['EeschemaConfigFile'] = file
    end

    opts.on('-m', '--colorscheme FILE', 'Use a color scheme file') do |file|
        options['ColorSchemeFile'] = file
    end

    opts.on('--generate FILE', 'Generate a color scheme file') do |file|
        options['NewColorSchemeFile'] = file
    end

    opts.on('-j', '--showdoubles', 'Shownewcolors which cannot be set independently') do
        options['ShowDoubles'] = true
    end

    opts.on('-w', '--wirecolor COLOR', 'Set wire color') do |color|
        newcolors['ColorWireEx'] = color
    end

    opts.on('-b', '--buscolor COLOR', 'Set bus color') do |color|
        newcolors['ColorBusEx'] = color
    end

    opts.on('-c', '--conncolor COLOR', 'Set connection dot color') do |color|
        newcolors['ColorConnEx'] = color
    end

    opts.on('-l', '--llabelcolor COLOR', 'Set local label color') do |color|
        newcolors['ColorLLabelEx'] = color
    end

    opts.on('-h', '--hlabelcolor COLOR', 'Set hierarchical label color') do |color|
        newcolors['ColorHLabelEx'] = color
    end

    opts.on('-g', '--glabelcolor COLOR', 'Set global label color') do |color|
        newcolors['ColorGLabelEx'] = color
    end

    opts.on('-n', '--pinnumcolor COLOR', 'Set pin number color') do |color|
        newcolors['ColorPinNumEx'] = color
    end

    opts.on('-p', '--pinnamecolor COLOR', 'Set pin name color') do |color|
        newcolors['ColorPinNameEx'] = color
    end

    opts.on('-f', '--fieldcolor COLOR', 'Set field color') do |color|
        newcolors['ColorFieldEx'] = color
    end

    opts.on('-r', '--refcolor COLOR', 'Set reference color') do |color|
        newcolors['ColorReferenceEx'] = color
    end

    opts.on('-v', '--valuecolor COLOR', 'Set value color') do |color|
        newcolors['ColorValueEx'] = color
    end

    opts.on('-t', '--notecolor COLOR', 'Set note color') do |color|
        newcolors['ColorNoteEx'] = color
    end

    opts.on('-d', '--bodycolor COLOR', 'Set body color') do |color|
        newcolors['ColorBodyEx'] = color
    end

    opts.on('-y', '--bodybgcolor COLOR', 'Set body background color') do |color|
        newcolors['ColorBodyBgEx'] = color
    end

    opts.on('-e', '--netnamecolor COLOR', 'Set net name color') do |color|
        newcolors['ColorNetNameEx'] = color
    end

    opts.on('-i', '--pincolor COLOR', 'Set pin color') do |color|
        newcolors['ColorPinEx'] = color
    end

    opts.on('-s', '--sheetcolor COLOR', 'Set sheet color') do |color|
        newcolors['ColorSheetEx'] = color
    end

    opts.on('-x', '--sheetfilenamecolor COLOR', 'Set sheet file name color') do |color|
        newcolors['ColorSheetFileNameEx'] = color
    end

    opts.on('-u', '--sheetnamecolor COLOR', 'Set sheet name color') do |color|
        newcolors['ColorSheetNameEx'] = color
    end

    opts.on('-a', '--sheetlabelcolor COLOR', 'Set sheet label color') do |color|
        newcolors['ColorSheetLabelEx'] = color
    end

    opts.on('-q', '--noconnectcolor COLOR', 'Set no connection mark color') do |color|
        newcolors['ColorNoConnectEx'] = color
    end

    opts.on('--ercwcolor COLOR', 'Set ERC warning color') do |color|
        newcolors['ColorErcWEx'] = color
    end

    opts.on('--ercecolor COLOR', 'Set ERC error color') do |color|
        newcolors['ColorErcEEx'] = color
    end

    opts.on('--gridcolor COLOR', 'Set grid color') do |color|
        newcolors['ColorGridEx'] = color
    end

    opts.on('-z', '--titlecolor COLOR', 'Set schematic title color') do |color|
        newcolors['ColorTitle'] = color
    end

    opts.on('-?', '--help', 'Help screen') do
        puts opts
        exit
    end
end

optparse.parse!

eeschemacolors = parseeeschemaconfig(options['EeschemaConfigFile'])
eeschemacolors['ColorTitle'] = 'Red 2'

# Check each color for validity and unify their syntax
newcolors.each do |key, color|
    newcolors[key] = checkcolor(color)
    if newcolors[key] == nil
        puts 'Error: "' + color + '" is not a valid color'
        exit 1
    end
end

if options['ShowDoubles'] == true
    showdoubles(eeschemacolors)
end

if options['NewColorSchemeFile'] != nil
    schemefile = File.open(options['NewColorSchemeFile'], 'w')
    schemefile.puts(YAML::dump(newcolors))
    schemefile.close()
end

if options['ColorSchemeFile'] != nil
    newcolors = YAML.load_file(options['ColorSchemeFile'])
end

# Create a hash with every text substitution to make
subs = Hash.new
newcolors.each do |colorname, colorvalue|
    if eeschemacolors[colorname] == nil
        puts 'Error: Color "' + colorname + '" not found in Eeschema config'
        exit 1
    end
    if $colordefinitions[eeschemacolors[colorname]] == nil
        puts 'Error: Unknown color: "' + eeschemacolors[colorname] + '"'
        exit 1
    end
    eeschemacolor = $colordefinitions[eeschemacolors[colorname]] + ' setrgbcolor'
    newcolor = hextops(colorvalue)
    if subs[eeschemacolor] != nil and subs[eeschemacolor] != newcolor
        puts 'Warning: Multiple different replacements for color "' + eeschemacolors[colorname] + '"'
    end
    subs[eeschemacolor] = newcolor
end

ARGV.each do |a|
    # Overwrite if no output file is given
    if options['OutputFile'] == nil 
        options['OutputFile'] = a
    end

    ifile = File.open(a, 'r')

    # Generate a file name for the temporary file
    tfilename = options['OutputFile']
    while File.exists?(tfilename + '.tmp') do
        tfilename += '_'
    end
    tfilename += '.tmp'

    tfile = File.open(tfilename, 'w')

    ifile.each do |line|
        if line['setrgbcolor']
            subs.each do |eeschemacolor, newcolor|
                line.sub!(eeschemacolor, newcolor)
            end
        end
        tfile.puts(line)
    end

    ifile.close()
    tfile.close()

    FileUtils.mv(tfilename, options['OutputFile'])
end

