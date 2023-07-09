require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
    def initialize(options = {})
        options.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true
        sql = "PRAGMA table_info(#{table_name})"
        column_names = []

        DB[:conn].execute(sql).map do |row|
            column_names << row["name"]
        end
        column_names.compact
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |col|
          values << "'#{send(col)}'" unless send(col).nil?
        end
        values.join(", ")
    end

    def save
        DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name name
        sql = "SELECT * FROM #{table_name} WHERE name = '#{name}'"
        DB[:conn].execute(sql)
    end

    def self.find_by attr= {}
        value = attr.values.first.class == Integer ? attr.values.first : "'#{attr.values.first}'" 
        sql = "SELECT * FROM #{table_name} WHERE #{attr.keys.first} = #{value}"
        DB[:conn].execute(sql)
    end
end