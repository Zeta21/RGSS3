module ZABS_Setup
#----------------------------------------------------------------------------
  PROJECTILES = { # Do not delete this line.
#----------------------------------------------------------------------------
    1 => {
      :character_name => "!Other1",
      :distance => 10,
      :knockback => 1,
      :piercing => 2,
      :initial_effect => %(RPG::SE.new("Earth9", 80).play),
      :hit_effect => %(@animation_id = 1)
    },
    2 => {
      :character_name => "!Other1",
      :character_index => 1,
      :distance => 10,
      :knockback => 2,
      :piercing => 2,
      :initial_effect => %(RPG::SE.new("Earth9", 80, 120).play),
      :hit_effect => %(@animation_id = 1)
    }
#----------------------------------------------------------------------------
  } # Do not delete this line.
#----------------------------------------------------------------------------
  PROJECTILE_DEFAULT = {
    :move_speed => 5,
    :through => true,
    :hit_jump => true,
    :ignore_spawn => true,
    :distance => 1,
    :knockback => 0,
    :piercing => 0,
    :size => 1,
    :battle_tags => ["player", "enemy"],
    :initial_effect => %(),
    :update_effect => %(),
    :hit_effect => %(),
    :end_effect => %()}
  HIT_COOLDOWN_TIME = 30
  DEATH_FADE_RATE = 4
  MISS_EFFECT = %(RPG::SE.new("Miss", 80).play)
#----------------------------------------------------------------------------
# * Regular Expressions
#----------------------------------------------------------------------------
  ENEMY_REGEX = /<enemy:\s*(\d+)>/i
  BATTLE_TAGS_REGEX = /<battle_tags:\s*(.*)>/i
  RESPAWN_TIME_REGEX = /<respawn_time:\s*(\d+)>/i
end

module ZABS_BattlerNotes
  def battle_tags
    match = @note.scan(ZABS_Setup::BATTLE_TAGS_REGEX)
    match.nil? ? [] : match.join(",").split(/,\s*/)
  end
end

class RPG::Actor
  include ZABS_BattlerNotes
end

class RPG::Enemy
  include ZABS_BattlerNotes
  def respawn_time
    @note[ZABS_Setup::RESPAWN_TIME_REGEX, 1].to_i
  end
end

module ZABS_Battler
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(*args)
    super
    @hit_cooldown = 0
  end
  #--------------------------------------------------------------------------
  # * New Method - attackable?
  #--------------------------------------------------------------------------
  def attackable?
    battler.alive? && @hit_cooldown.zero?
  end
  #--------------------------------------------------------------------------
  # * New Method - battle_tags_check?
  #--------------------------------------------------------------------------
  def battle_tags_check?(projectile)
    battler.data.battle_tags.each do |x|
      return true if projectile.battle_tags.include?(x)
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * New Method - apply_projectile
  #--------------------------------------------------------------------------
  def apply_projectile(projectile)
    return unless attackable? && battle_tags_check?(projectile)
    @hit_cooldown = ZABS_Setup::HIT_COOLDOWN_TIME
    battler.item_apply(projectile.battler, projectile.item)
    battler.result.hit? ? process_hit(projectile) : process_miss
  end
  #--------------------------------------------------------------------------
  # * New Method - process_hit
  #--------------------------------------------------------------------------
  def process_hit(projectile)
    projectile.piercing -= 1
    eval(projectile.hit_effect)
    jump(0, 0) if projectile.hit_jump
    process_knockback(projectile)
  end
  #--------------------------------------------------------------------------
  # * New Method - process_miss
  #--------------------------------------------------------------------------
  def process_miss
    eval(ZABS_Setup::MISS_EFFECT)
  end
  #--------------------------------------------------------------------------
  # * New Method - process_knockback
  #--------------------------------------------------------------------------
  def process_knockback(projectile)
    @direction_fix = valid = true unless @direction_fix
    projectile.knockback.times {move_straight(projectile.direction)}
    @direction_fix = false if valid
  end
  #--------------------------------------------------------------------------
  # * New Method - update_hit_cooldown
  #--------------------------------------------------------------------------
  def update_hit_cooldown
    @hit_cooldown -= 1 unless @hit_cooldown.zero?
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    update_hit_cooldown
  end
end

class Game_Map
  attr_accessor :need_refresh_projectiles
  attr_reader :projectiles
  #--------------------------------------------------------------------------
  # * Alias Method - setup
  #--------------------------------------------------------------------------
  alias zabs_map_setup setup
  def setup(map_id)
    zabs_map_setup(map_id)
    setup_mapenemies
    @projectiles = []
    @need_refresh_projectiles = true
    @need_refresh = true
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update
  #--------------------------------------------------------------------------
  alias zabs_map_update update
  def update(main=false)
    zabs_map_update(main)
    update_projectiles
  end
  #--------------------------------------------------------------------------
  # * New Method - setup_mapenemies
  #--------------------------------------------------------------------------
  def setup_mapenemies
    @events.each {|k,v| @events[k] = v.to_enemyevent}
  end
  #--------------------------------------------------------------------------
  # * New Method - events_inrange
  #--------------------------------------------------------------------------
  def events_inrange(x, y, d)
    @events.values.select {|e| e.in_range?(x, y, d)}
  end
  #--------------------------------------------------------------------------
  # * New Method - add_projectile
  #--------------------------------------------------------------------------
  def add_projectile(projectile)
    @projectiles.push(projectile)
    @need_refresh_projectiles = true
  end
  #--------------------------------------------------------------------------
  # * New Method - update_projectiles
  #--------------------------------------------------------------------------
  def update_projectiles
    valid = @projectiles.reject!(&:need_dispose)
    @need_refresh_projectiles = true if valid
    @projectiles.each(&:update)
  end
end

class Game_Actor < Game_Battler
  alias_method :data, :actor
end

class Game_Character < Game_CharacterBase
  #--------------------------------------------------------------------------
  # * New Method - in_range?
  #--------------------------------------------------------------------------
  def in_range?(x, y, d)
    distance_x_from(x).abs + distance_y_from(y).abs < d
  end
end

class Game_Player < Game_Character
  include ZABS_Battler
  alias_method :battler, :actor
end

class Game_Event
  #--------------------------------------------------------------------------
  # * New Method - is_enemy?
  #--------------------------------------------------------------------------
  def is_enemy?
    ZABS_Setup::ENEMY_REGEX =~ @event.name
  end
  #--------------------------------------------------------------------------
  # * New Method - to_enemyevent
  #--------------------------------------------------------------------------
  def to_enemyevent
    is_enemy? ? Game_EnemyEvent.new(@map_id, @event) : self
  end
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  # * Alias Method - create_characters
  #--------------------------------------------------------------------------
  alias zabs_map_create_characters create_characters
  def create_characters
    zabs_map_create_characters
    create_projectiles
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update_characters
  #--------------------------------------------------------------------------
  alias zabs_map_update_characters update_characters
  def update_characters
    if $game_map.need_refresh_projectiles
      refresh_projectiles
      $game_map.need_refresh_projectiles = false
    end
    zabs_map_update_characters
  end
  #--------------------------------------------------------------------------
  # * New Method - create_projectiles
  #--------------------------------------------------------------------------
  def create_projectiles
    $game_map.projectiles.each do |x|
      @character_sprites.push(Sprite_Character.new(@viewport1, x))
    end
  end
  #--------------------------------------------------------------------------
  # * New Method - dispose_projectiles
  #--------------------------------------------------------------------------
  def dispose_projectiles
    @character_sprites.each do |x|
      x.dispose if x.character.is_a?(Game_Projectile)
    end
    @character_sprites.reject! {|x| x.character.is_a?(Game_Projectile)}
  end
  #--------------------------------------------------------------------------
  # * New Method - refresh_projectiles
  #--------------------------------------------------------------------------
  def refresh_projectiles
    dispose_projectiles
    create_projectiles
  end
end

class Game_MapEnemy < Game_Battler
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(enemy_id)
    super()
    @enemy_id = enemy_id
    @hp, @mp = mhp, mmp
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - param_base
  #--------------------------------------------------------------------------
  def param_base(param_id)
    data.params[param_id]
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - feature_objects
  #--------------------------------------------------------------------------
  def feature_objects
    super + [data]
  end
  #--------------------------------------------------------------------------
  # * New Method - data
  #--------------------------------------------------------------------------
  def data
    $data_enemies[@enemy_id]
  end
end

class Game_Projectile < Game_Character
  attr_accessor :piercing
  attr_reader :type, :battler, :item, :hit_jump, :knockback, :battle_tags
  attr_reader :hit_effect, :need_dispose
  #--------------------------------------------------------------------------
  # * New Class Method - spawn
  #--------------------------------------------------------------------------
  def self.spawn(*args)
    projectile = self.new(*args)
    $game_map.add_projectile(projectile)
  end
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(type, character, item)
    super()
    moveto(character.x, character.y)
    @type, @character, @item = type, character, item
    @direction, @battler = character.direction, character.battler
    initialize_projectile
    yield if block_given?
  end
  #--------------------------------------------------------------------------
  # * New Method - initialize_projectile
  #--------------------------------------------------------------------------
  def initialize_projectile
    attrs = ZABS_Setup::PROJECTILE_DEFAULT.merge(data)
    attrs.each {|k, v| instance_variable_set("@#{k}", v)}
    eval(@initial_effect)
  end
  #--------------------------------------------------------------------------
  # * New Method - stopping?
  #--------------------------------------------------------------------------
  def stopping?
    @distance.zero?
  end
  #--------------------------------------------------------------------------
  # * New Method - data
  #--------------------------------------------------------------------------
  def data
    ZABS_Setup::PROJECTILES[@type]
  end
  #--------------------------------------------------------------------------
  # * New Method - valid_targets
  #--------------------------------------------------------------------------
  def valid_targets
    arr = $game_map.events_inrange(@x, @y, @size).select(&:is_enemy?)
    arr.push($game_player) if $game_player.in_range?(@x, @y, @size)
    arr.reject! {|x| @character.equal?(x)} if @ignore_spawn
    return arr
  end
  #--------------------------------------------------------------------------
  # * New Method - move_projectile
  #--------------------------------------------------------------------------
  def move_projectile
    return if stopping? || moving?
    move_forward
    @distance -= 1
  end
  #--------------------------------------------------------------------------
  # * New Method - update_effects
  #--------------------------------------------------------------------------
  def update_effects
    eval(@update_effect)
    valid_targets.each {|x| x.apply_projectile(self)}
  end
  #--------------------------------------------------------------------------
  # * New Method - update_end
  #--------------------------------------------------------------------------
  def update_end
    return unless @piercing < 0 || stopping?
    eval(@end_effect)
    @need_dispose = true
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    update_effects
    update_end
    move_projectile
  end
end

class Game_EnemyEvent < Game_Event
  include ZABS_Battler
  attr_reader :battler
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(map_id, event)
    super
    @battler = Game_MapEnemy.new(enemy_id)
    @respawn_time = @battler.data.respawn_time
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - update_self_movement
  #--------------------------------------------------------------------------
  def update_self_movement
    return if @battler.dead?
    super
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - is_enemy?
  #--------------------------------------------------------------------------
  def is_enemy?
    return true
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - to_enemyevent
  #--------------------------------------------------------------------------
  def to_enemyevent
    return self
  end
  #--------------------------------------------------------------------------
  # * New Method - enemy_id
  #--------------------------------------------------------------------------
  def enemy_id
    @event.name[ZABS_Setup::ENEMY_REGEX, 1].to_i
  end
  #--------------------------------------------------------------------------
  # * New Method - process_death
  #--------------------------------------------------------------------------
  def process_death
    @opacity > 0 ? @opacity -= ZABS_Setup::DEATH_FADE_RATE : erase
  end
  #--------------------------------------------------------------------------
  # * New Method - process_respawn
  #--------------------------------------------------------------------------
  def process_respawn
    return if @respawn_time.nil?
    @respawn_time > 0 ? @respawn_time -= 1 : initialize(@map_id, @event)
  end
  #--------------------------------------------------------------------------
  # * New Method - update_death
  #--------------------------------------------------------------------------
  def update_death
    return unless @battler.dead?
    @erased ? process_respawn : process_death
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    update_death
    super
  end
end
