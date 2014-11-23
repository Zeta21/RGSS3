module ZABS_Setup
#----------------------------------------------------------------------------
  PROJECTILES = { # Do not delete this line.
#----------------------------------------------------------------------------
    1 => {
      character_name: "!Other1",
      distance: 10,
      knockback: 1,
      piercing: 5,
      initial_effect: %(RPG::SE.new("Earth9", 80).play),
      hit_effect: %(@animation_id = 1)
    },
    2 => {
      character_name: "Monster3",
      through: true,
      hit_jump: false,
      distance: 10,
      initial_effect: %(RPG::SE.new("Monster3", 80).play),
      hit_effect: %(@animation_id = 1)
    },
    3 => {
      through: true,
      hit_jump: false,
      distance: 0,
      hit_effect: %(@animation_id = 3)
    }
#----------------------------------------------------------------------------
  } # Do not delete this line.
#----------------------------------------------------------------------------
  PROJECTILE_DEFAULT = {
    move_speed: 5,
    hit_jump: true,
    battler_through: true,
    ignore_user: true,
    size: 1,
    distance: 1,
    knockback: 0,
    piercing: 0,
    initial_effect: %(),
    update_effect: %(),
    hit_effect: %(),
    end_effect: %()
  }
  HIT_COOLDOWN_TIME = 30
  TURN_UPDATE_TIME = 60
  DEATH_FADE_RATE = 4
  MISS_EFFECT = %(RPG::SE.new("Miss", 80).play)
#----------------------------------------------------------------------------
# * Regular Expressions
#----------------------------------------------------------------------------
  BATTLE_TAGS_REGEX = /<battle[ _]tags:\s*(.*)>/i
  ITEM_PROJECTILE_REGEX = /<projectile:\s*(\d+)/i
  ITEM_COOLDOWN_REGEX = /<cooldown:\s*(\d+)/i
  IMMOVABLE_REGEX = /<immovable>/i
  DEATH_EFFECT_REGEX = /<death[ _]effect>(.*)<\/death[ _]effect>/im
  RESPAWN_TIME_REGEX = /<respawn[ _]time:\s*(\d+)>/i
  RESPAWN_EFFECT_REGEX = /<respawn[ _]effect>(.*)<\/respawn[ _]effect>/im
  ENEMY_REGEX = /<enemy:\s*(\d+)>/i
end

module ZABS_ItemNotes
  #--------------------------------------------------------------------------
  # * New Method - abs_item?
  #--------------------------------------------------------------------------
  def abs_item?
    projectile
  end
  #--------------------------------------------------------------------------
  # * New Method - projectile
  #--------------------------------------------------------------------------
  def projectile
    match = @note[ZABS_Setup::ITEM_PROJECTILE_REGEX, 1]
    match.to_i if match
  end
  #--------------------------------------------------------------------------
  # * New Method - cooldown
  #--------------------------------------------------------------------------
  def cooldown
    match = @note[ZABS_Setup::ITEM_COOLDOWN_REGEX, 1].to_i
  end
end

module ZABS_BattlerNotes
  #--------------------------------------------------------------------------
  # * New Method - immovable?
  #--------------------------------------------------------------------------
  def immovable?
    @note =~ ZABS_Setup::IMMOVABLE_REGEX
  end
  #--------------------------------------------------------------------------
  # * New Method - respawn_effect
  #--------------------------------------------------------------------------
  def death_effect
    match = @note[ZABS_Setup::DEATH_EFFECT_REGEX, 1].to_s
  end
end

class RPG::BaseItem
  #--------------------------------------------------------------------------
  # * New Method - battle_tags
  #--------------------------------------------------------------------------
  def battle_tags
    match = @note.scan(ZABS_Setup::BATTLE_TAGS_REGEX).to_a
    match.join(" ").split(/\s+/)
  end
end

class RPG::UsableItem
  include ZABS_ItemNotes
end

class RPG::EquipItem
  include ZABS_ItemNotes
end

class RPG::Actor
  include ZABS_BattlerNotes
end

class RPG::Enemy
  include ZABS_BattlerNotes
  #--------------------------------------------------------------------------
  # * New Method - respawn_time
  #--------------------------------------------------------------------------
  def respawn_time
    match = @note[ZABS_Setup::RESPAWN_TIME_REGEX, 1]
    match.to_i if match
  end
  #--------------------------------------------------------------------------
  # * New Method - respawn_effect
  #--------------------------------------------------------------------------
  def respawn_effect
    match = @note[ZABS_Setup::RESPAWN_EFFECT_REGEX, 1].to_s
  end
end

module ZABS_Battler
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(*args)
    super
    @update_time = ZABS_Setup::TURN_UPDATE_TIME
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - usable?
  #--------------------------------------------------------------------------
  def usable?(item)
    return equippable?(item) if item.is_a?(RPG::EquipItem)
    return super
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    return (@update_time -= 1) unless @update_time.zero?
    @update_time = ZABS_Setup::TURN_UPDATE_TIME
    on_turn_end
    refresh
  end
end

module ZABS_Character
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(*args)
    super
    @hit_cooldown = 0
    @item_cooldown = Hash.new(0)
  end
  #--------------------------------------------------------------------------
  # * New Method - abs_item_usable?
  #--------------------------------------------------------------------------
  def abs_item_usable?(item)
    item.abs_item? && battler.usable?(item) && \
    @item_cooldown[item].zero?
  end
  #--------------------------------------------------------------------------
  # * New Method - use_abs_skill
  #--------------------------------------------------------------------------
  def use_abs_skill(skill_id)
    process_item_use($data_skills[skill_id])
  end
  #--------------------------------------------------------------------------
  # * New Method - use_abs_item
  #--------------------------------------------------------------------------
  def use_abs_item(item_id)
    process_item_use($data_items[item_id])
  end
  #--------------------------------------------------------------------------
  # * New Method - use_abs_weapon
  #--------------------------------------------------------------------------
  def use_abs_weapon(weapon_id)
    process_item_use($data_weapons[weapon_id])
  end
  #--------------------------------------------------------------------------
  # * New Method - attackable?
  #--------------------------------------------------------------------------
  def process_item_use(item)
    return unless abs_item_usable?(item)
    if item.is_a?(RPG::UsableItem) && item.for_user?
      return unless battler.item_test(battler, item)
      battler.item_apply(battler, item)
    else
      Game_Projectile.spawn(item.projectile, self, item)
    end
    @item_cooldown[item] = item.cooldown
    battler.use_item(item)
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
    (battler.data.battle_tags & projectile.item.battle_tags).any?
  end
  #--------------------------------------------------------------------------
  # * New Method - apply_projectile
  #--------------------------------------------------------------------------
  def apply_projectile(projectile)
    return unless attackable? && battle_tags_check?(projectile)
    @hit_cooldown = ZABS_Setup::HIT_COOLDOWN_TIME
    battler.item_apply(projectile.battler, projectile.effect_item)
    battler.result.hit? ? process_hit(projectile) : process_miss
  end
  #--------------------------------------------------------------------------
  # * New Method - process_hit
  #--------------------------------------------------------------------------
  def process_hit(projectile)
    projectile.piercing -= 1
    eval(projectile.hit_effect)
    process_knockback(projectile) unless battler.data.immovable?
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
    jump(0, 0) if projectile.hit_jump
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
  # * New Method - update_item_cooldown
  #--------------------------------------------------------------------------
  def update_item_cooldown
    @item_cooldown.each do |k, v|
      @item_cooldown[k] = v.pred unless v.zero?
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    update_hit_cooldown
    update_item_cooldown
  end
end

class Game_Actor < Game_Battler
  include ZABS_Battler
  alias_method :data, :actor
end

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # * New Method - rotate_actors
  #--------------------------------------------------------------------------
  def rotate_actors
    return if members.all?(&:dead?)
    @actors.rotate! until $game_player.actor.alive?
  end
  #--------------------------------------------------------------------------
  # * New Method - update_members
  #--------------------------------------------------------------------------
  def update_members
    members.each(&:update)
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
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update
  #--------------------------------------------------------------------------
  alias zabs_map_update update
  def update(main=false)
    zabs_map_update(main)
    update_projectiles
    $game_party.update_members
  end
  #--------------------------------------------------------------------------
  # * New Method - setup_mapenemies
  #--------------------------------------------------------------------------
  def setup_mapenemies
    @events.each {|k,v| @events[k] = v.to_enemyevent}
  end
  #--------------------------------------------------------------------------
  # * New Method - events_xyd
  #--------------------------------------------------------------------------
  def events_xyd(x, y, d)
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

class Game_Character < Game_CharacterBase
  #--------------------------------------------------------------------------
  # * New Method - in_range?
  #--------------------------------------------------------------------------
  def in_range?(x, y, d)
    distance_x_from(x).abs + distance_y_from(y).abs < d
  end
end

class Game_Player < Game_Character
  include ZABS_Character
  alias_method :battler, :actor
  #--------------------------------------------------------------------------
  # * Alias Method - update
  #--------------------------------------------------------------------------
  alias zabs_player_update update
  def update
    zabs_player_update
    update_death
  end
  #--------------------------------------------------------------------------
  # * New Method - update_death
  #--------------------------------------------------------------------------
  def update_death
    return if actor.alive?
    eval(actor.data.death_effect)
    $game_party.rotate_actors
    refresh
  end
end

class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # * New Method - is_enemy?
  #--------------------------------------------------------------------------
  def is_enemy?
    is_a?(Game_EnemyEvent)
  end
  #--------------------------------------------------------------------------
  # * New Method - to_enemyevent
  #--------------------------------------------------------------------------
  def to_enemyevent
    return self unless @event.name =~ ZABS_Setup::ENEMY_REGEX
    event = Game_EnemyEvent.new(@map_id, @event)
    instance_variables.each do |s|
      event.instance_variable_set(s, instance_variable_get(s))
    end
    return event
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
  include ZABS_Battler
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
  attr_reader :battler, :item, :hit_jump, :knockback, :hit_effect
  attr_reader :need_dispose
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
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - collide_with_events?
  #--------------------------------------------------------------------------
  def collide_with_events?(x, y)
    return false unless super
    return true unless @battler_through
    events = $game_map.events_xy_nt(x, y).reject(&:is_enemy?)
    events.any?(&:normal_priority?)
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
  # * New Method - effect_item
  #--------------------------------------------------------------------------
  def effect_item
    @item.is_a?(RPG::EquipItem) ? $data_skills[1] : @item
  end
  #--------------------------------------------------------------------------
  # * New Method - valid_targets
  #--------------------------------------------------------------------------
  def valid_targets
    arr = $game_map.events_xyd(@x, @y, @size).select(&:is_enemy?)
    arr.push($game_player) if $game_player.in_range?(@x, @y, @size)
    arr.reject! {|x| x.equal?(@character)} if @ignore_user
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
  include ZABS_Character
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
  # * New Method - respawn
  #--------------------------------------------------------------------------
  def respawn
    initialize(@map_id, @event)
    eval(@battler.data.respawn_effect)
  end
  #--------------------------------------------------------------------------
  # * New Method - process_death
  #--------------------------------------------------------------------------
  def process_death
    eval(@battler.data.death_effect) if @opacity == 255
    @opacity > 0 ? @opacity -= ZABS_Setup::DEATH_FADE_RATE : erase
  end
  #--------------------------------------------------------------------------
  # * New Method - process_respawn
  #--------------------------------------------------------------------------
  def process_respawn
    return if @respawn_time.nil?
    @respawn_time > 0 ? @respawn_time -= 1 : respawn
  end
  #--------------------------------------------------------------------------
  # * New Method - update_death
  #--------------------------------------------------------------------------
  def update_death
    return if @battler.alive?
    @erased ? process_respawn : process_death
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    @battler.update
    update_death
    super
  end
end
