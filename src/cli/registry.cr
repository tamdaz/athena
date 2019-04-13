module Athena::Cli
  # Stores the available commands.
  struct Registry
    macro finished
      # Array of available commands.  Auto registered at compile time.
      class_getter commands : Array(Athena::Cli::Command.class) = {% if Athena::Cli::Command.subclasses.size > 0 %}{{Athena::Cli::Command.subclasses}} {% else %} [] {% end %} of Athena::Cli::Command.class
    end

    # Displays the available commands.
    def self.to_s : String
      String.build do |str|
        groups = @@commands.group_by { |g| g.name.count(':').zero? ? "" : g.name.split(':').first }
        group_names = groups.keys.reject(&.==("")).sort
        group_names << "" if groups.has_key? ""

        str.puts "Registered Commands:"
        group_names.each do |group|
          str.puts "\t#{group.empty? ? "ungrouped" : group}"
          groups[group].sort_by(&.name).each do |c|
            next if c.name.blank? || c.description.blank?
            str.puts "\t\t#{c.name} - #{c.description}"
          end
        end
      end
    end

    # Returns the command with the given name.
    #
    # Raises if no command has that name.
    def self.find(name : String) : Athena::Cli::Command.class
      command_class = @@commands.find { |c| c.name == name }
      raise "No command with the name '#{name}' has been registered" if command_class.nil?
      command_class
    end
  end
end