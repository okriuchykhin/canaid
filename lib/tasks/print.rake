namespace :canaid do
  MD_FILE_PATH = 'permissions.md'.freeze
  GENERIC_CLASS_NAME = 'Canaid::PermissionsHolder::Generic'.freeze
  CAN_REGEX = /^( *)can +.* +(do|\{) +\|.+\| *$/

  def print(markdown = false)
    # Fetch variables off the permissions holder instance
    ph = Canaid::PermissionsHolder.instance
    can_obj_classes = ph.instance_variable_get(:@can_obj_classes)
    cans = ph.instance_variable_get(:@cans)

    output = []

    obj_classes = can_obj_classes
                  .values
                  .select { |oc| oc != GENERIC_CLASS_NAME }
    # Start with generic
    obj_classes.unshift(GENERIC_CLASS_NAME)

    obj_classes.uniq.each do |obj_class|
      if obj_class == GENERIC_CLASS_NAME
        output << '## Generic permissions'
      else
        output << "## #{obj_class} permissions"
      end
      output << ''

      permission_names =
        can_obj_classes.map { |k, v| v == obj_class ? k : nil }.compact
      permission_names.sort!
      permission_names.each do |pn|
        next if cans[pn].empty?


        output << "### #{pn}"
        output << ''
        perms = cans[pn].sort { |e1, e2| e1[:priority] <=> e2[:priority] }
        perms.each_with_index do |perm, idx|
          output << '```ruby' if markdown

          source = perm[:block].source

          # Get rid of empty lines and uneccesary indentation
          md = CAN_REGEX.match(source)
          ws = md && md.length > 1 ? md[1] : ''

          source_lines = perm[:block].source.split("\n")
          idx_s, idx_f = 0, 0
          source_lines.each_with_index do |line, i|
            idx_s = i && break if line =~ CAN_REGEX
          end
          source_lines.reverse.each_with_index do |line, i|
            idx_f = i && break if line =~ /^.*end.*$/
          end
          idx_f = source_lines.length - 1 - idx_f

          # Specify the location where permission is defined
          sl = perm[:block].source_location
          output << "# #{sl[0]}, line #{sl[1]}"

          # Print the Proc itself
          source_lines[idx_s..idx_f].each do |line|
            output << (line.start_with?(ws) ? line[ws.length..-1] : line)
          end

          output << '```' if markdown

          output << '' if idx < perms.length - 1
        end

        output << ''
      end
    end

    return output.join("\n")
  end

  desc 'Print all permissions definitions'
  task print: :environment do
    puts print(false)
  end

  desc 'Save all permissions definitions to permissions.md'
  task print_md: :environment do
    File.delete(MD_FILE_PATH) if File.exist?(MD_FILE_PATH)
    File.open(MD_FILE_PATH, 'w') do |file|
      file.write(print(true))
    end
  end
end
