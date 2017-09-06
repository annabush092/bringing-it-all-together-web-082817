require 'pry'

class Dog

  attr_accessor :name, :breed
  attr_reader :id

  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT
        breed TEXT
      )
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
      DROP TABLE dogs
    SQL
    DB[:conn].execute(sql)
  end

  def initialize(hash)
    @name = hash[:name]
    @breed = hash[:breed]
    @id = hash[:id]
  end

#create instances from the db

  def self.new_from_db(row_array)
    #create a new instance from the db
    Dog.new(id: row_array[0], name: row_array[1], breed: row_array[2])
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE id = ?
    SQL
    self.new_from_db(DB[:conn].execute(sql, id).flatten)
  end

  def self.find_by_name(name)
    #find dog in sql
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE name = ?
    SQL
    #return instance of found dog
    self.new_from_db(DB[:conn].execute(sql, name).flatten)
  end

#change the db based on instances
  def update
    #find dog we want to update by id, and change it in the db
    sql = <<-SQL
      UPDATE dogs
      SET name = ?, breed = ?
      WHERE id = ?
    SQL
    DB[:conn].execute(sql, self.name, self.breed, self.id)
    #return updated dog instance
    self
  end

  def save
    #puts dog instance into the db
    #is dog already in the db (does it have an id)? If so, update
    if !!self.id
      self.update
    #if not already in the db, create new entry in db
    else
      sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      SQL
      DB[:conn].execute(sql, self.name, self.breed)
    #find the id and assign to the instance
      sql = <<-SQL
        SELECT id
        FROM dogs
        ORDER BY id DESC
        LIMIT 1
      SQL
      @id = DB[:conn].execute(sql).flatten.first
    end
    self
  end

#add a new dog to both the class and to the db
  def self.create(hash)
    Dog.new(hash).save
  end

  def self.find_or_create_by(name_breed_hash)
    #does dog instance exist in db?
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE name = ? AND breed = ?
    SQL
    found = DB[:conn].execute(sql, name_breed_hash[:name], name_breed_hash[:breed])
    if found.flatten.length >= 1
      #dog exists, create instance and return.
      Dog.new_from_db(found.flatten)
    else
      #if no, create a new instance and db entry and return instance
      Dog.create(name_breed_hash)
    end
  end

end
