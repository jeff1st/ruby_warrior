class RubyWarrior::Turn
  @@busy ||= false
  @@recov ||= false
  @@path_back = Array.new

  def is_busy?
   @@busy
  end

  def is_busy=(val)
    @@busy = val
  end

  def is_healthy?
    self.health > 16
  end

  def is_combat_recov?
    @@recov
  end

  def is_combat_recov=(val)
    @@recov = val
  end

  def path_back_set(val)
    @@path_back << val
  end

  def path_back_get
    @@path_back.pop
  end

  def path_back_read(num)
    @@path_back[num]
  end
end


class Player
  def play_turn(warrior)
    @monsters = {'Sludge' => 12, 'Thick Sludge' => 24}
    @dangerous = {'Thick Sludge' => 24}
    @warrior_detects = Hash.new
    @directions = [:forward, :backward, :right, :left]
    @contraries = {:forward => :backward, :backward => :forward, :left => :right, :right => :left}
    
    to_stairs = warrior.direction_of_stairs
    look_around(warrior)

    #IA
    
    if zone_safe? && !warrior.is_combat_recov? && !warrior.is_busy?         #Place is safe
      if warrior.is_healthy?                                                #Check if warrior is in good cond to travel
        if path_blocked?                                                    #Something is in the way
          from_blocked_zone = to_stairs
          alternative_way = degaging(from_blocked_zone)                     #Find a new way
          warrior.walk!(alternative_way)                                    #And walk that new direction
        else
          warrior.walk!(to_stairs)                                          #Moving (ATTENTION, must walk back to combat)
        end
      else
        warrior.rest!                                                       #If not in good condition => rest
      end

    elsif zone_safe? && warrior.is_combat_recov?                            #Place is safe and combat is running
      if warrior.is_healthy?                                                #Check if warrior is in good cond to travel
        go_back_to_fight(warrior)                                           #Health = ok and going back to fight
      else
        warrior.rest!                                                       #Rest until combat capable
      end
      
    elsif !zone_safe? && warrior.is_combat_recov?
        to_rest = to_stairs
        alternative_way = degaging(to_rest)                                 #Find a quiet place to rest
        warrior.walk!(escaping_to_rest)

    else                                                                    #Place is not safe
      if warrior.is_busy? && zone_safe?                                     #Combat is over
        warrior.is_busy= false                                              #Enter quiet mod
        puts "Warrior is hanging around now"
        warrior.rest!

      elsif monsters_around?                                                #More than 1 monster around
        puts "Monsters have been seen"

      elsif monster_around?                               #Only one monster around
        in_monster_direction = find_monster
        if warrior.is_busy?                               #Combat has started
          if warrior.health >= 10                         #Healthy enough to continue (limit can be modified)
            warrior.attack!(in_monster_direction)
          else
            warrior.is_combat_recov= true                 #Enter recovery mod
            escape_direction = escape(warrior)
            warrior.walk!(escape_direction)               #Escaping to rest
          end

        else                                              #Opportunity for a new combat
          if warrior.is_healthy?
            warrior.is_busy= true                         #Enter combat mod
            warrior.attack!(in_monster_direction)
          else
            warrior.is_combat_recov= true                 #Enter recovery mod
            escape_direction = escape(warrior)
            warrior.walk!(escape_direction)               #Escaping to rest
          end
        end

      else                                                #Must be blocked by something
        from_blocked_zone = to_stairs
        alternative_way = degaging(from_blocked_zone)     #Find a new way
        warrior.walk!(alternative_way)                    #And walk that new direction
      end
    end

  end

  def look_around(warrior)
    @directions.each { |direction| @warrior_detects[direction] = warrior.feel(direction).to_s }
  end

  def zone_safe?
    @warrior_detects.values.none? { |monster| @monsters.include?(monster) }
  end

  def monster_around?
    count = @warrior_detects.values.select { |monster| @monsters.include?(monster) }
    count.length == 1
  end

  def monsters_around?
    count = @warrior_detects.values.select { |monster| @monsters.include?(monster) }
    count.length > 1
  end

  def find_monster
    monster_position = String.new
    @warrior_detects.each { |position, monster| monster_position = position if @monsters.include?(monster) }
    return monster_position
  end

  def path_blocked?
    count = @warrior_detects.values.select { |look| look == "nothing" }
    count.length == 1
  end

  def degaging(from_direction)
    to_direction = ""
    val = false
    while val == false
      to_direction = @directions[rand(4)]
      val = true if @warrior_detects[to_direction] == "nothing"
    end
    return to_direction
  end
  
  def escape(warrior)
    escape_direction = ""
    val = false
    while val == false
      escape_direction = @directions[rand(4)]
      val = true if @warrior_detects[escape_direction] == "nothing"
    end
    warrior.path_back_set(@contraries[escape_direction])
    return escape_direction
  end

  def go_back_to_fight(warrior)                                                 #Consumes path back until fight zone
    fight_zone = warrior.path_back_get
    warrior.is_combat_recov= false if warrior.path_back_read(0).nil?
    warrior.walk!(fight_zone)
  end

end
