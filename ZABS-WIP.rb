module ZABS_Setup
#--------------------------------------------------------------------------
  PROJECTILES = { # Do not delete this line.
#--------------------------------------------------------------------------
    1 => {:character_name => "!Other1",
          :move_speed => 5,
          :through => true,
          :distance => 10,
          :hit_jump => true,
          :knockback => 1,
          :piercing => 1,
          :use_effect => %(RPG::SE.new("Earth9", 80).play),
          :hit_effect => %(@animation_id = 1),
          :end_effect => %()}
#--------------------------------------------------------------------------
  } # Do not delete this line.
#--------------------------------------------------------------------------
  HIT_COOLDOWN_TIME = 30
  MISS_SE = ["Miss", 80, 100]
  DEATH_FADE_RATE = 4
  ENEMY_REGEX = /\<enemy:\s*(\d+)\>/i
end
 
module ZABS_Control
  #--------------------------------------------------------------------------
  # * New Method - make_actor_projectile
  #--------------------------------------------------------------------------
  def self.make_actor_projectile(character, type, item)
    x, y, dir = character.x, character.y, character.direction
    user = character.enemy
    projectile = Game_Projectile.new(x, y, dir, type, user, item)
    $game_map.add_projectile(projectile)
  end
end
 
module ZABS_Battler
  attr_reader :hit_cooldown
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(*args)
    super(*args)
    @hit_cooldown = 0
  end
  #--------------------------------------------------------------------------
  # * New Method - apply_projectile
  #--------------------------------------------------------------------------
  def apply_projectile(projectile)
    return if enemy.dead?
    enemy.item_apply(projectile.user, projectile.item)
    @hit_cooldown = ZABS_Setup::HIT_COOLDOWN_TIME
    enemy.result.hit? ? process_hit(projectile) : process_miss(projectile)
  end
  #--------------------------------------------------------------------------
  # * New Method - process_hit
  #--------------------------------------------------------------------------
  def process_hit(projectile)
    eval(projectile.hit_effect)
    jump(0, 0) if projectile.hit_jump
    process_knockback(projectile)
  end
  #--------------------------------------------------------------------------
  # * New Method - process_miss
  #--------------------------------------------------------------------------
  def process_miss(projectile)
    RPG::SE.new(*ZABS_Setup::MISS_SE).play
  end
  #--------------------------------------------------------------------------
  # * New Method - process_knockback
  #--------------------------------------------------------------------------
  def process_knockback(projectile)
    @direction_fix = valid = true unless @direction_fix
    count = projectile.knockback
    count.times {move_straight(projectile.direction, false)}
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
  attr_reader :projectiles
  attr_accessor :need_refresh_projectiles
  #--------------------------------------------------------------------------
  # * Alias Method - setup
  #--------------------------------------------------------------------------
  alias zabs_setup setup
  def setup(map_id)
    zabs_setup(map_id)
    setup_mapenemies
    @projectiles = []
    @need_refresh_projectiles = true
    @need_refresh = true
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update
  #--------------------------------------------------------------------------
  alias zabs_update update
  def update(main=false)
    zabs_update(main)
    update_projectiles
  end
  #--------------------------------------------------------------------------
  # * New Method - setup_mapenemies
  #--------------------------------------------------------------------------
  def setup_mapenemies
    @events.each {|k,v| @events[k] = v.to_enemyevent}
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
    return if @projectiles.empty?
    valid = @projectiles.reject!(&:need_dispose)
    @need_refresh_projectiles = true if valid
    @projectiles.each(&:update)
  end
end
 
class Game_Player < Game_Character
  include ZABS_Battler
  alias_method :enemy, :actor
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
    return self unless is_enemy?
    return Game_EnemyEvent.new(@map_id, @event)
  end
end
 
class Spriteset_Map
  #--------------------------------------------------------------------------
  # * Alias Method - create_characters
  #--------------------------------------------------------------------------
  alias zabs_create_characters create_characters
  def create_characters
    zabs_create_characters
    create_projectiles
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update_characters
  #--------------------------------------------------------------------------
  alias zabs_update_characters update_characters
  def update_characters
    if $game_map.need_refresh_projectiles
      refresh_projectiles
      $game_map.need_refresh_projectiles = false
    end
    zabs_update_characters
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
    @character_sprites.delete_if {|x| x.character.is_a?(Game_Projectile)}
  end
  #--------------------------------------------------------------------------
  # * New Method - refresh_projectiles
  #--------------------------------------------------------------------------
  def refresh_projectiles
    dispose_projectiles
    create_projectiles
  end
end
 
class Game_Projectile < Game_Character
  attr_reader :user, :item, :hit_jump, :knockback
  attr_reader :hit_effect, :need_dispose
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, dir, type, user, item)
    super()
    moveto(x, y)
    @direction = dir
    @type = type
    @user = user
    @item = item
    initialize_projectile
  end
  #--------------------------------------------------------------------------
  # * New Method - initialize_projectile
  #--------------------------------------------------------------------------
  def initialize_projectile
    projectile_data.each do |k, v|
      s = "@#{k}".to_sym
      instance_variable_set(s, v)
    end
    eval(@use_effect)
  end
  #--------------------------------------------------------------------------
  # * New Method - stopping?
  #--------------------------------------------------------------------------
  def stopping?
    @distance.zero?
  end
  #--------------------------------------------------------------------------
  # * New Method - projectile_data
  #--------------------------------------------------------------------------
  def projectile_data
    ZABS_Setup::PROJECTILES[@type]
  end
  #--------------------------------------------------------------------------
  # * New Method - valid_targets
  #--------------------------------------------------------------------------
  def valid_targets # FIXME
    arr = $game_map.events_xy(@x, @y)
    arr.keep_if(&:is_enemy?)
    if user.is_a?(Game_MapEnemy)
      arr.delete_if(&:is_enemy?)
      arr.push($game_player) if $game_player.pos?(@x, @y)
    end
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
    valid_targets.each do |x|
      next if x.enemy.dead? || x.hit_cooldown > 0
      x.apply_projectile(self)
      @piercing -= 1 if x.enemy.result.hit?
    end
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
    update_effects
    update_end
    move_projectile
    super
  end
end
 
class Game_MapEnemy < Game_Battler
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(enemy_id)
    super()
    @enemy_id = enemy_id
    @hp = mhp
    @mp = mmp
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - param_base
  #--------------------------------------------------------------------------
  def param_base(param_id)
    enemy_data.params[param_id]
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - feature_objects
  #--------------------------------------------------------------------------
  def feature_objects
    super + [enemy_data]
  end
  #--------------------------------------------------------------------------
  # * New Method - enemy_data
  #--------------------------------------------------------------------------
  def enemy_data
    $data_enemies[@enemy_id]
  end
end
 
class Game_EnemyEvent < Game_Event
  include ZABS_Battler
  attr_reader :enemy
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(map_id, event)
    super
    @enemy = Game_MapEnemy.new(enemy_id)
  end
  #--------------------------------------------------------------------------
  # * New Method - to_enemyevent
  #--------------------------------------------------------------------------
  def to_enemyevent
    return self
  end
  #--------------------------------------------------------------------------
  # * New Method - enemy_id
  #--------------------------------------------------------------------------
  def enemy_id
    match = ZABS_Setup::ENEMY_REGEX.match(@event.name)
    return match[1].to_i
  end
  #--------------------------------------------------------------------------
  # * New Method - update_death
  #--------------------------------------------------------------------------
  def update_death
    return unless @enemy.dead?
    @opacity > 0 ? @opacity -= ZABS_Setup::DEATH_FADE_RATE : erase
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    update_death
    super
  end
end
