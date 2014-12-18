#============================================================================
# ** Start of configuration
#============================================================================
module ZABS_Setup
#----------------------------------------------------------------------------
  PROJECTILES = { # Do not delete this line.
#----------------------------------------------------------------------------
    1 => { # Sword
      move_speed: 4,
      knockback: 1,
      initial_effect: %{RPG::SE.new("Wind7", 80).play},
      hit_effect: %{RPG::SE.new("Sword4", 80).play},
    },
    2 => { # Arrow
      character_name: "$Arrow",
      move_speed: 6,
      distance: 10,
      knockback: 1,
      initial_effect: %{RPG::SE.new("Bow2", 80).play},
      hit_effect: %{@animation_id = 1},
    },
    3 => { # Bomb
      character_name: "!Other1",
      character_index: 3,
      hit_jump: false,
      distance: 8,
      hit_cooldown: 0,
      initial_effect: %{RPG::SE.new("Earth9", 80).play},
      end_effect: %{chain(4, $data_skills[128])},
    },
    4 => { # Explosion
      allow_collision: false,
      size: 4,
      distance: 0,
      ignore: :none,
      initial_effect: %{@animation_id = 3},
    },
    5 => { # Spear
      move_speed: 4,
      size: 2,
      knockback: 2,
      initial_effect: %{RPG::SE.new("Wind7", 80).play},
      hit_effect: %{RPG::SE.new("Sword4", 80).play},
    },
    6 => { # Area Heal
      size: 5,
      distance: 0,
      hit_jump: false,
      allow_collision: false,
      ignore: :enemy,
      hit_effect: %{@animation_id = 3},
    },
#----------------------------------------------------------------------------
  } # Do not delete this line.
#----------------------------------------------------------------------------
  END_TURN_TIME = 120
  DEATH_FADE_RATE = 4
  HUD_BACK_COLOR = [0, 0, 0, 255]
#----------------------------------------------------------------------------
  HUD_FRONT_COLORS = { # Do not delete this line.
#----------------------------------------------------------------------------
    1 => [255, 0, 0, 255],
    2 => [255, 128, 0, 255],
    3 => [255, 255, 0, 255],
    4 => [0, 255, 0, 255],
    5 => [0, 192, 255, 255],
#----------------------------------------------------------------------------
  } # Do not delete this line.
#----------------------------------------------------------------------------
# * Advanced Settings
#----------------------------------------------------------------------------
  PROJECTILE_DEFAULT = {
    move_speed: 5,
    allow_collision: true,
    battler_through: true,
    hit_jump: true,
    reflective: false,
    distance: 1,
    hit_cooldown: 30,
    knockback: 0,
    piercing: 0,
    size: 1,
    ignore: :ally,
    collide_effect: %{},
    end_effect: %{},
    hit_effect: %{},
    initial_effect: %{},
    update_effect: %{},
  }
  SELF_ITEM_USAGE = true
  MISS_EFFECT = %(RPG::SE.new("Miss", 80).play)
  EVADE_EFFECT = %(RPG::SE.new("Miss", 80).play)
  KEY_MAP_EXTRA = {COMMA: 0xBC, PERIOD: 0xBE}
#----------------------------------------------------------------------------
# * Regular Expressions
#----------------------------------------------------------------------------
  module Regexp
    ACTING_LOCK = /<acting[ _]lock>/i
    ACTING_TIME = /<acting[ _]time:\s*(\d+)>/i
    BATTLE_TAGS = /<battle[ _]tags:\s*(.*)>/i
    COOLDOWN = /<cooldown:\s*(\d+)>/i
    DEATH_EFFECT = /<death[ _]effect>(.*)<\/death[ _]effect>/im
    EFFECT_ITEM = /<effect[ _]item:\s*(skill|item)\s+(\d+)>/i
    ENEMY = /<enemy:\s*(\d+)>/i
    EVADE_JUMP = /<evade[ _]jump>/i
    GRAPHIC_INDEX = /<graphic[ _]index:\s*(\d+)>/i
    GRAPHIC_NAME = /<graphic[ _]name:\s*(.*)>/i
    HIDE_HUD = /<hide_hud>/
    HIT_EFFECT = /<hit[ _]effect>(.*)<\/hit[ _]effect>/im
    IMMOVABLE = /<immovable>/i
    KEEP_CORPSE = /<keep[ _]corpse>/i
    LEFT_HANDED = /<left[ _]handed>/i
    PROJECTILE = /<projectile:\s*(\d+)>/i
    RESPAWN_EFFECT = /<respawn[ _]effect>(.*)<\/respawn[ _]effect>/im
    RESPAWN_TIME = /<respawn[ _]time:\s*(\d+)>/i
    RIGHT_HANDED = /<right[ _]handed>/i
    SIZE = /<size:\s*(\d+)>/i
  end
end
#============================================================================
# ** End of configuration
#============================================================================

#============================================================================
# ** New Module - ZABS_input
#============================================================================
module ZABS_Input
  #--------------------------------------------------------------------------
  # * Initial Setup - GetKeyState
  #--------------------------------------------------------------------------
  GetKeyState = Win32API.new("user32", "GetKeyState", "I", "I")
  #--------------------------------------------------------------------------
  # * Initial Setup - key_map
  #--------------------------------------------------------------------------
  @key_map = ZABS_Setup::KEY_MAP_EXTRA.dup
  (0..9).each {|x| @key_map.store("NUMBER_#{x}".intern, x.to_s.ord)}
  ("A".."Z").each {|x| @key_map.store("LETTER_#{x}".intern, x.ord)}
  #--------------------------------------------------------------------------
  # * Initial Setup - key_states
  #--------------------------------------------------------------------------
  @key_states = {}
  @key_map.each_key {|x| @key_states.store(x, 0)}
  #--------------------------------------------------------------------------
  # * New Class Method - press?
  #--------------------------------------------------------------------------
  def self.press?(key)
    @key_states[key] > 0
  end
  #--------------------------------------------------------------------------
  # * New Class Method - trigger?
  #--------------------------------------------------------------------------
  def self.trigger?(key)
    @key_states[key].between?(1, 2)
  end
  #--------------------------------------------------------------------------
  # * New Class Method - update
  #--------------------------------------------------------------------------
  def self.update
    @key_map.each do |k, v|
      state = GetKeyState.call(v) >> 8
      state.zero? ? @key_states[k] = 0 : @key_states[k] += 1
    end
  end
end

#============================================================================
# ** New Module - ZABS_Usable
#============================================================================
module ZABS_Usable
  #--------------------------------------------------------------------------
  # * New Method - abs_item?
  #--------------------------------------------------------------------------
  def abs_item?
    projectile > 0
  end
  #--------------------------------------------------------------------------
  # * New Method - acting_lock?
  #--------------------------------------------------------------------------
  def acting_lock?
    @acting_lock ||= @note =~ ZABS_Setup::Regexp::ACTING_LOCK
  end
  #--------------------------------------------------------------------------
  # * New Method - right_handed?
  #--------------------------------------------------------------------------
  def right_handed?
    @right_handed ||= @note =~ ZABS_Setup::Regexp::RIGHT_HANDED
  end
  #--------------------------------------------------------------------------
  # * New Method - left_handed?
  #--------------------------------------------------------------------------
  def left_handed?
    @left_handed ||= @note =~ ZABS_Setup::Regexp::LEFT_HANDED
  end
  #--------------------------------------------------------------------------
  # * New Method - projectile
  #--------------------------------------------------------------------------
  def projectile
    return @projectile if @projectile
    match = @note[ZABS_Setup::Regexp::PROJECTILE, 1]
    @projectile = match ? match.to_i : -1
  end
  #--------------------------------------------------------------------------
  # * New Method - cooldown
  #--------------------------------------------------------------------------
  def cooldown
    @cooldown ||= @note[ZABS_Setup::Regexp::COOLDOWN, 1].to_i
  end
  #--------------------------------------------------------------------------
  # * New Method - graphic_name
  #--------------------------------------------------------------------------
  def graphic_name
    @graphic_name ||= @note[ZABS_Setup::Regexp::GRAPHIC_NAME, 1].to_s
  end
  #--------------------------------------------------------------------------
  # * New Method - graphic_index
  #--------------------------------------------------------------------------
  def graphic_index
    @graphic_index ||= @note[ZABS_Setup::Regexp::GRAPHIC_INDEX, 1].to_i
  end
  #--------------------------------------------------------------------------
  # * New Method - acting_time
  #--------------------------------------------------------------------------
  def acting_time
    return @acting_time if @acting_time
    match = @note[ZABS_Setup::Regexp::ACTING_TIME, 1].to_i
    @acting_time = [match, 3].max
  end
  #--------------------------------------------------------------------------
  # * New Method - effect_item
  #--------------------------------------------------------------------------
  def effect_item
    match = @note.scan(ZABS_Setup::Regexp::EFFECT_ITEM).to_a.flatten
    case match.first
    when "skill" then $data_skills[match[1].to_i]
    when "item" then $data_items[match[1].to_i]
    end
  end
end

#============================================================================
# ** New Module - ZABS_Attackable
#============================================================================
module ZABS_Attackable
  #--------------------------------------------------------------------------
  # * New Method - immovable?
  #--------------------------------------------------------------------------
  def immovable?
    @immovable ||= @note =~ ZABS_Setup::Regexp::IMMOVABLE
  end
  #--------------------------------------------------------------------------
  # * New Method - evade_jump?
  #--------------------------------------------------------------------------
  def evade_jump?
    @evade_jump ||= @note =~ ZABS_Setup::Regexp::EVADE_JUMP
  end
  #--------------------------------------------------------------------------
  # * New Method - keep_corpse?
  #--------------------------------------------------------------------------
  def keep_corpse?
    @keep_corpse ||= @note =~ ZABS_Setup::Regexp::KEEP_CORPSE
  end
  #--------------------------------------------------------------------------
  # * New Method - hide_hud?
  #--------------------------------------------------------------------------
  def hide_hud?
    @hide_hud ||= @note =~ ZABS_Setup::Regexp::HIDE_HUD
  end
  #--------------------------------------------------------------------------
  # * New Method - size
  #--------------------------------------------------------------------------
  def size
    return @size if @size
    match = @note[ZABS_Setup::Regexp::SIZE, 1].to_i
    @size = [match, 1].max
  end
  #--------------------------------------------------------------------------
  # * New Method - hit_effect
  #--------------------------------------------------------------------------
  def hit_effect
    @hit_effect ||= @note[ZABS_Setup::Regexp::HIT_EFFECT, 1].to_s
  end
  #--------------------------------------------------------------------------
  # * New Method - death_effect
  #--------------------------------------------------------------------------
  def death_effect
    @death_effect ||= @note[ZABS_Setup::Regexp::DEATH_EFFECT, 1].to_s
  end
end

#============================================================================
# ** Reopen Class - RPG::BaseItem
#============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # * New Method - battle_tags
  #--------------------------------------------------------------------------
  def battle_tags
    return @battle_tags if @battle_tags
    match = @note.scan(ZABS_Setup::Regexp::BATTLE_TAGS).to_a
    @battle_tags = match.join(" ").split(/\s+/)
  end
end

#============================================================================
# ** Reopen Class - RPG::Usable
#============================================================================
class RPG::UsableItem < RPG::BaseItem
  include ZABS_Usable
  #--------------------------------------------------------------------------
  # * Overwrite Method - effect_item
  #--------------------------------------------------------------------------
  def effect_item
    return @effect_item if @effect_item
    @effect_item = super || self
  end
  #--------------------------------------------------------------------------
  # * New Method - for_allies?
  #--------------------------------------------------------------------------
  def for_allies?
    @scope.between?(7, 10)
  end
end

#============================================================================
# ** Reopen Class - RPG::EquipItem
#============================================================================
class RPG::EquipItem < RPG::BaseItem
  include ZABS_Usable
  #--------------------------------------------------------------------------
  # * Overwrite Method - effect_item
  #--------------------------------------------------------------------------
  def effect_item
    return @effect_item if @effect_item
    @effect_item = super || $data_skills[1]
  end
end

#============================================================================
# ** Reopen Class - RPG::Actor
#============================================================================
class RPG::Actor < RPG::BaseItem
  include ZABS_Attackable
end

#============================================================================
# ** Reopen Class - RPG::Enemy
#============================================================================
class RPG::Enemy < RPG::BaseItem
  include ZABS_Attackable
  #--------------------------------------------------------------------------
  # * New Method - respawn_time
  #--------------------------------------------------------------------------
  def respawn_time
    return @respawn_time if @respawn_time
    match = @note[ZABS_Setup::Regexp::RESPAWN_TIME, 1].to_i
    @respawn_time = match > 0 ? match : -1
  end
  #--------------------------------------------------------------------------
  # * New Method - respawn_effect
  #--------------------------------------------------------------------------
  def respawn_effect
    @respawn_effect ||= @note[ZABS_Setup::Regexp::RESPAWN_EFFECT, 1].to_s
  end
end

#============================================================================
# ** New Module - ZABS_Battler
#============================================================================
module ZABS_Battler
  attr_accessor :item_cooldown
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(*args)
    super
    @end_turn_time = ZABS_Setup::END_TURN_TIME
    @item_cooldown = Hash.new(0)
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - occasion_ok?
  #--------------------------------------------------------------------------
  def occasion_ok?(item)
    SceneManager.scene_is?(Scene_Map) ? item.battle_ok? : item.menu_ok?
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - use_item
  #--------------------------------------------------------------------------
  def use_item(item)
    super(item.effect_item)
    @item_cooldown[item] = item.cooldown
  end
  #--------------------------------------------------------------------------
  # * New Method - update_item_cooldown
  #--------------------------------------------------------------------------
  def update_item_cooldown
    @item_cooldown.each {|k, v| @item_cooldown[k] -= 1 unless v.zero?}
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    update_item_cooldown
    return unless (@end_turn_time -= 1).zero?
    @end_turn_time = ZABS_Setup::END_TURN_TIME
    on_turn_end
    refresh
  end
end

#============================================================================
# ** New Module - ZABS_Entity
#============================================================================
module ZABS_Entity
  #--------------------------------------------------------------------------
  # * New Method - in_range?
  #--------------------------------------------------------------------------
  def in_range?(x, y, d)
    distance_x_from(x).abs + distance_y_from(y).abs < d + size - 1
  end
  #--------------------------------------------------------------------------
  # * New Method - ally?
  #--------------------------------------------------------------------------
  def ally?(entity)
    battler.data.battle_tags == entity.battler.data.battle_tags
  end
  #--------------------------------------------------------------------------
  # * New Method - friend?
  #--------------------------------------------------------------------------
  def friend?(entity)
    (battler.data.battle_tags & entity.battler.data.battle_tags).any?
  end
  #--------------------------------------------------------------------------
  # * New Method - enemy?
  #--------------------------------------------------------------------------
  def enemy?(entity)
    (battler.data.battle_tags & entity.battler.data.battle_tags).empty?
  end
  #--------------------------------------------------------------------------
  # * New Method - allies
  #--------------------------------------------------------------------------
  def allies
    $game_map.battlers.select {|x| ally?(x)}
  end
  #--------------------------------------------------------------------------
  # * New Method - friends
  #--------------------------------------------------------------------------
  def friends
    $game_map.battlers.select {|x| friend?(x)}
  end
  #--------------------------------------------------------------------------
  # * New Method - enemies
  #--------------------------------------------------------------------------
  def enemies
    $game_map.battlers.select {|x| enemy?(x)}
  end
  #--------------------------------------------------------------------------
  # * New Method - ally_target
  #--------------------------------------------------------------------------
  def ally_target
    return @ally if @ally && @ally.battler.alive?
    targets = allies.select {|x| x.battler.alive?} - [self]
    (@ally = targets.sample) || self
  end
  #--------------------------------------------------------------------------
  # * New Method - friend_target
  #--------------------------------------------------------------------------
  def friend_target
    return @friend if @friend && @friend.battler.alive?
    targets = friends.select {|x| x.battler.alive?} - [self]
    (@friend = targets.sample) || self
  end
  #--------------------------------------------------------------------------
  # * New Method - enemy_target
  #--------------------------------------------------------------------------
  def enemy_target
    return @enemy if @enemy && @enemy.battler.alive?
    targets = enemies.select {|x| x.battler.alive?} - [self]
    (@enemy = targets.sample) || self
  end
end

#============================================================================
# ** New Module - ZABS_Character
#============================================================================
module ZABS_Character
  include ZABS_Entity
  attr_accessor :acting_lock
  attr_reader :map_item
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(*args)
    super
    @hit_cooldown = 0
    @map_item = Game_MapItem.new(self)
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - passable?
  #--------------------------------------------------------------------------
  def passable?(x, y, d)
    @acting_lock ? false : super
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - update_anime_pattern
  #--------------------------------------------------------------------------
  def set_direction(d)
    super unless @acting_lock
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - update_anime_pattern
  #--------------------------------------------------------------------------
  def update_anime_pattern
    @acting_lock ? @pattern = 0 : super
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - draw_hud?
  #--------------------------------------------------------------------------
  def draw_hud?
    return false unless battler
    !battler.data.hide_hud? && battler.alive? && (battler.hp < battler.mhp)
  end
  #--------------------------------------------------------------------------
  # * New Method - attackable?
  #--------------------------------------------------------------------------
  def attackable?
    battler.alive? && @hit_cooldown.zero?
  end
  #--------------------------------------------------------------------------
  # * New Method - battle_tags_match?
  #--------------------------------------------------------------------------
  def battle_tags_match?(projectile)
    (battler.data.battle_tags & projectile.item.battle_tags).any?
  end
  #--------------------------------------------------------------------------
  # * New Method - item_map_usable?
  #--------------------------------------------------------------------------
  def item_map_usable?(item)
    return false unless battler.usable?(item)
    item.abs_item? || item.is_a?(RPG::UsableItem)
  end
  #--------------------------------------------------------------------------
  # * New Method - size
  #--------------------------------------------------------------------------
  def size
    battler.data.size
  end
  #--------------------------------------------------------------------------
  # * New Method - hp_rate
  #--------------------------------------------------------------------------
  def hp_rate
    battler.hp.to_f / battler.mhp
  end
  #--------------------------------------------------------------------------
  # * New Method - use_abs_skill
  #--------------------------------------------------------------------------
  def use_abs_skill(*args)
    process_map_item($data_skills[args.sample])
  end
  #--------------------------------------------------------------------------
  # * New Method - use_abs_item
  #--------------------------------------------------------------------------
  def use_abs_item(*args)
    process_map_item($data_items[args.sample])
  end
  #--------------------------------------------------------------------------
  # * New Method - use_abs_weapon
  #--------------------------------------------------------------------------
  def use_abs_weapon(*args)
    process_map_item($data_weapons[args.sample])
  end
  #--------------------------------------------------------------------------
  # * New Method - use_abs_armor
  #--------------------------------------------------------------------------
  def use_abs_armor(*args)
    process_map_item($data_armors[args.sample])
  end
  #--------------------------------------------------------------------------
  # * New Method - process_map_item
  #--------------------------------------------------------------------------
  def process_map_item(item)
    return unless item_map_usable?(item)
    if item.abs_item?
      @map_item.set_item(item)
      Game_Projectile.spawn(self, item.projectile, item)
      battler.use_item(item)
    else
      process_normal_item(item)
    end
  end
  #--------------------------------------------------------------------------
  # * New Method - process_normal_item
  #--------------------------------------------------------------------------
  def process_normal_item(item)
    return unless item.for_user? && @battler.item_test(actor, item)
    actor.use_item(item)
    actor.item_apply(actor, item)
  end
  #--------------------------------------------------------------------------
  # * New Method - apply_projectile
  #--------------------------------------------------------------------------
  def apply_projectile(projectile)
    return unless attackable? && battle_tags_match?(projectile)
    @hit_cooldown = projectile.hit_cooldown
    battler.item_apply(projectile.battler, projectile.item.effect_item)
    battler.result.hit? ? process_hit(projectile) : process_miss
  end
  #--------------------------------------------------------------------------
  # * New Method - process_hit
  #--------------------------------------------------------------------------
  def process_hit(projectile)
    @acting_lock = false
    eval(battler.data.hit_effect)
    eval(projectile.hit_effect)
    projectile.piercing -= 1
    process_knockback(projectile) unless battler.data.immovable?
  end
  #--------------------------------------------------------------------------
  # * New Method - process_miss
  #--------------------------------------------------------------------------
  def process_miss
    if battler.result.missed
      eval(ZABS_Setup::MISS_EFFECT)
    elsif battler.result.evaded
      eval(ZABS_Setup::EVADE_EFFECT)
      jump(0, 0) if battler.data.evade_jump?
    end
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
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    update_hit_cooldown
    @map_item.update
  end
end

#============================================================================
# ** Reopen Class - Game_Actor
#============================================================================
class Game_Actor < Game_Battler
  include ZABS_Battler
  alias_method :data, :actor
  #--------------------------------------------------------------------------
  # * Overwrite Method - usable?
  #--------------------------------------------------------------------------
  def usable?(item)
    item && @item_cooldown[item].zero? ? super(item.effect_item) : false
  end
end

#============================================================================
# ** Reopen Class - Game_Party
#============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # * New Method - rotate_actors
  #--------------------------------------------------------------------------
  def rotate_actors
    return if members.all?(&:dead?)
    @actors.rotate! until members.first.alive?
  end
end

#============================================================================
# ** Reopen Class - Game_Map
#============================================================================
class Game_Map
  attr_reader :projectiles
  #--------------------------------------------------------------------------
  # * Alias Method - setup
  #--------------------------------------------------------------------------
  alias zabs_map_setup setup
  def setup(map_id)
    zabs_map_setup(map_id)
    @projectiles = []
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update
  #--------------------------------------------------------------------------
  alias zabs_map_update update
  def update(main=false)
    zabs_map_update(main)
    update_projectiles
    $game_party.members.each(&:update)
  end
  #--------------------------------------------------------------------------
  # * New Method - battlers
  #--------------------------------------------------------------------------
  def battlers
    @events.values.select(&:battler).push($game_player)
  end
  #--------------------------------------------------------------------------
  # * New Method - battlers_xyd
  #--------------------------------------------------------------------------
  def battlers_xyd(x, y, d)
    battlers.select {|b| b.in_range?(x, y, d)}
  end
  #--------------------------------------------------------------------------
  # * New Method - entities
  #--------------------------------------------------------------------------
  def entities
    battlers.concat(@projectiles)
  end
  #--------------------------------------------------------------------------
  # * New Method - entities_xyd
  #--------------------------------------------------------------------------
  def entities_xyd(x, y, d)
    entities.select {|e| e.in_range?(x, y, d)}
  end
  #--------------------------------------------------------------------------
  # * New Method - add_projectile
  #--------------------------------------------------------------------------
  def add_projectile(projectile)
    @projectiles.push(projectile)
  end
  #--------------------------------------------------------------------------
  # * New Method - update_projectiles
  #--------------------------------------------------------------------------
  def update_projectiles
    @projectiles.reject!(&:need_dispose)
    @projectiles.each(&:update)
  end
end

#============================================================================
# ** Reopen Class - Game_CharacterBase
#============================================================================
class Game_CharacterBase
  #--------------------------------------------------------------------------
  # * New Method - draw_hud?
  #--------------------------------------------------------------------------
  def draw_hud?
    return false
  end
end

#============================================================================
# ** Reopen Class - Game_Player
#============================================================================
class Game_Player < Game_Character
  include ZABS_Character
  alias_method :battler, :actor
  #--------------------------------------------------------------------------
  # * Overwrite Method - item_map_usable?
  #--------------------------------------------------------------------------
  def item_map_usable?(item)
    item.is_a?(RPG::UsableItem) && item.for_allies? ? true : super
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - process_normal_item
  #--------------------------------------------------------------------------
  def process_normal_item(item)
    return super unless item.for_allies?
    SceneManager.call(Scene_MapItem)
    SceneManager.scene.item = item
  end
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

#============================================================================
# ** Reopen Class - Game_Event
#============================================================================
class Game_Event < Game_Character
  include ZABS_Character
  attr_reader :battler
  #--------------------------------------------------------------------------
  # * Alias Method - initialize
  #--------------------------------------------------------------------------
  alias zabs_event_initialize initialize
  def initialize(*args)
    zabs_event_initialize(*args)
    initialize_battler
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update_self_movement
  #--------------------------------------------------------------------------
  alias zabs_event_update_self_movement update_self_movement
  def update_self_movement
    return if @acting_lock || (@battler && @battler.dead?)
    zabs_event_update_self_movement
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update
  #--------------------------------------------------------------------------
  alias zabs_event_update update
  def update
    zabs_event_update
    update_battler
  end
  #--------------------------------------------------------------------------
  # * New Method - initialize_battler
  #--------------------------------------------------------------------------
  def initialize_battler
    return if enemy_id.zero?
    @dead = false
    @battler = Game_MapEnemy.new(enemy_id)
    @respawn_time = @battler.data.respawn_time
  end
  #--------------------------------------------------------------------------
  # * New Method - enemy_id
  #--------------------------------------------------------------------------
  def enemy_id
    @enemy_id ||= @event.name[ZABS_Setup::Regexp::ENEMY, 1].to_i
  end
  #--------------------------------------------------------------------------
  # * New Method - kill_event
  #--------------------------------------------------------------------------
  def kill_event
    eval(battler.data.death_effect)
    @dead = true
  end
  #--------------------------------------------------------------------------
  # * New Method - respawn
  #--------------------------------------------------------------------------
  def respawn
    initialize(@map_id, @event)
    eval(@battler.data.respawn_effect)
  end
  #--------------------------------------------------------------------------
  # * New Method - control_self_switch
  #--------------------------------------------------------------------------
  def control_self_switch(key, value, reset_dir=true)
    $game_self_switches[[@map_id, @id, key]] = value
    @original_direction = nil if reset_dir
  end
  #--------------------------------------------------------------------------
  # * New Method - process_death
  #--------------------------------------------------------------------------
  def process_death
    return kill_event if @battler.data.keep_corpse?
    return unless (@opacity -= ZABS_Setup::DEATH_FADE_RATE) < 0
    kill_event
    erase
  end
  #--------------------------------------------------------------------------
  # * New Method - process_respawn
  #--------------------------------------------------------------------------
  def process_respawn
    return if @respawn_time < 0
    respawn if (@respawn_time -= 1).zero?
  end
  #--------------------------------------------------------------------------
  # * New Method - update_death
  #--------------------------------------------------------------------------
  def update_death
    return if @battler.alive?
    @dead ? process_respawn : process_death
  end
  #--------------------------------------------------------------------------
  # * New Method - update_battler
  #--------------------------------------------------------------------------
  def update_battler
    return unless @battler
    update_death
    @battler.update
  end
end

#============================================================================
# ** Reopen Class - Sprite_Character
#============================================================================
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # * Initial Setup - hud_front_colors
  #--------------------------------------------------------------------------
  @@hud_front_colors = {}
  ZABS_Setup::HUD_FRONT_COLORS.each do |k, v|
    @@hud_front_colors.store(k, Color.new(*v))
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update
  #--------------------------------------------------------------------------
  alias zabs_sprite_character_update update
  def update
    zabs_sprite_character_update
    update_hud
    update_map_item
  end
  #--------------------------------------------------------------------------
  # * Alias Method - dispose
  #--------------------------------------------------------------------------
  alias zabs_sprite_character_dispose dispose
  def dispose
    dispose_hud
    @map_item_sprite.dispose if @map_item_sprite
    zabs_sprite_character_dispose
  end
  #--------------------------------------------------------------------------
  # * New Method - hud_width
  #--------------------------------------------------------------------------
  def hud_width
    width + 8
  end
  #--------------------------------------------------------------------------
  # * New Method - hud_bar_width
  #--------------------------------------------------------------------------
  def hud_bar_width
    (width + 6) * @character.hp_rate
  end
  #--------------------------------------------------------------------------
  # * New Method - hud_back_color
  #--------------------------------------------------------------------------
  def hud_back_color
    @hud_back_color ||= Color.new(*ZABS_Setup::HUD_BACK_COLOR)
  end
  #--------------------------------------------------------------------------
  # * New Method - hud_front_color
  #--------------------------------------------------------------------------
  def hud_front_color
    level = (@@hud_front_colors.keys.max * @character.hp_rate).ceil
    @@hud_front_colors[level]
  end
  #--------------------------------------------------------------------------
  # * New Method - setup_hud
  #--------------------------------------------------------------------------
  def setup_hud
    @hud_sprite = Sprite.new(viewport)
    @hud_sprite.bitmap = Bitmap.new(hud_width, 4)
  end
  #--------------------------------------------------------------------------
  # * New Method - dispose_hud
  #--------------------------------------------------------------------------
  def dispose_hud
    @hud_sprite.bitmap.clear
    @hud_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # * New Method - update_hud_position
  #--------------------------------------------------------------------------
  def update_hud_position
    @hud_sprite.x = x - width / 2 - 4
    @hud_sprite.y = y - height - 4
    @hud_sprite.z = z + 200
  end
  #--------------------------------------------------------------------------
  # * New Method - update_hud_bar_width
  #--------------------------------------------------------------------------
  def update_hud_width
    return if @hud_sprite.bitmap.width == hud_width
    @hud_sprite.bitmap.dispose
    @hud_sprite.bitmap = Bitmap.new(hud_width, 4)
    @last_hp_rate = nil
  end
  #--------------------------------------------------------------------------
  # * New Method - update_hud_bar_width
  #--------------------------------------------------------------------------
  def update_hud_bar_width
    return if @last_hp_rate == (@last_hp_rate = @character.hp_rate)
    @hud_sprite.bitmap.fill_rect(0, 0, hud_width, 4, hud_back_color)
    @hud_sprite.bitmap.fill_rect(1, 1, hud_bar_width, 2, hud_front_color)
  end
  #--------------------------------------------------------------------------
  # * New Method - update_hud
  #--------------------------------------------------------------------------
  def update_hud
    setup_hud unless @hud_sprite
    return (@hud_sprite.bitmap.clear) unless @character.draw_hud?
    update_hud_position
    update_hud_width
    update_hud_bar_width
  end
  #--------------------------------------------------------------------------
  # * New Method - update_map_item
  #--------------------------------------------------------------------------
  def update_map_item
    return unless @character.is_a?(ZABS_Character)
    @map_item_sprite ||= Sprite_MapItem.new(viewport, @character.map_item)
    @map_item_sprite.update
  end
end

#============================================================================
# ** Reopen Class - Spriteset_Map
#============================================================================
class Spriteset_Map
  #--------------------------------------------------------------------------
  # * Alias Method - create_characters
  #--------------------------------------------------------------------------
  alias zabs_spriteset_map_create_characters create_characters
  def create_characters
    zabs_spriteset_map_create_characters
    create_projectiles
  end
  #--------------------------------------------------------------------------
  # * Alias Method - update_characters
  #--------------------------------------------------------------------------
  alias zabs_spriteset_map_update_characters update_characters
  def update_characters
    zabs_spriteset_map_update_characters
    dispose_projectiles
    update_projectiles
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
  # * New Method - update_projectiles
  #--------------------------------------------------------------------------
  def update_projectiles
    $game_map.projectiles.reject(&:sprite_drawn).each do |x|
      @character_sprites.push(Sprite_Character.new(@viewport1, x))
      x.sprite_drawn = true
    end
  end
  #--------------------------------------------------------------------------
  # * New Method - dispose_projectiles
  #--------------------------------------------------------------------------
  def dispose_projectiles
    sprites = @character_sprites.select do |x|
      next unless x.character.is_a?(Game_Projectile)
      x.character.need_dispose && !x.animation?
    end
    sprites.each(&:dispose)
    @character_sprites.reject!(&:disposed?)
  end
end

#============================================================================
# ** Reopen Class - Scene_Map
#============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # * Alias Method - update
  #--------------------------------------------------------------------------
  alias zabs_scene_map_update update
  def update
    zabs_scene_map_update
    ZABS_Input.update
  end
end

#============================================================================
# ** Reopen Class - Scene_Item
#============================================================================
class Scene_ItemBase < Scene_MenuBase
  #--------------------------------------------------------------------------
  # * Alias Method - user
  #--------------------------------------------------------------------------
  alias zabs_scene_itembase_user user
  def user
    if ZABS_Setup::SELF_ITEM_USAGE
      $game_party.members[@actor_window.index]
    else
      zabs_scene_itembase_user
    end
  end
end

#============================================================================
# ** New Subclass - Game_MapEnemy
#============================================================================
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
  # * Overwrite Method - usable?
  #--------------------------------------------------------------------------
  def usable?(item)
    return false unless @item_cooldown[item].zero?
    item.is_a?(RPG::Skill) ? super : item.is_a?(ZABS_Usable)
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
  # * Overwrite Method - consume_item
  #--------------------------------------------------------------------------
  def consume_item(item)
  end
  #--------------------------------------------------------------------------
  # * New Method - data
  #--------------------------------------------------------------------------
  def data
    $data_enemies[@enemy_id]
  end
end

#============================================================================
# ** New Subclass - Game_MapItem
#============================================================================
class Game_MapItem < Game_CharacterBase
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(character)
    super()
    @character = character
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - direction
  #--------------------------------------------------------------------------
  def direction
    @character.direction
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - screen_x
  #--------------------------------------------------------------------------
  def screen_x
    @character.screen_x
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - screen_y
  #--------------------------------------------------------------------------
  def screen_y
    @character.screen_y
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - screen_z
  #--------------------------------------------------------------------------
  def screen_z
    @character.screen_z - offset_z
  end
  #--------------------------------------------------------------------------
  # * New Method - offset_z
  #--------------------------------------------------------------------------
  def offset_z
    return 0 unless @item
    valid = case direction
    when 2 then false
    when 4 then @item.right_handed?
    when 6 then @item.left_handed?
    when 8 then true
    end
    valid ? 1 : 0
  end
  #--------------------------------------------------------------------------
  # * New Method - set_item
  #--------------------------------------------------------------------------
  def set_item(item)
    @pattern = 0
    @item = item
    @character_name = item.graphic_name
    @character_index = item.graphic_index
    @acting_time = item.acting_time / 3
    @character.acting_lock = true if item.acting_lock?
  end
  #--------------------------------------------------------------------------
  # * New Method - remove_item
  #--------------------------------------------------------------------------
  def remove_item
    @item = nil
    @character_name = ""
    @character.acting_lock = false
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    return unless @item && (@acting_time -= 1).zero?
    @acting_time = @item.acting_time / 3
    remove_item if (@pattern += 1) >= 3
  end
end

#============================================================================
# ** New Subclass - Game_Projectile
#============================================================================
class Game_Projectile < Game_Character
  include ZABS_Entity
  attr_accessor :piercing, :sprite_drawn, :need_dispose
  attr_reader :type, :battler, :item, :hit_jump, :reflective, :knockback
  attr_reader :size, :hit_cooldown, :hit_effect, :collide_effect
  #--------------------------------------------------------------------------
  # * New Class Method - spawn
  #--------------------------------------------------------------------------
  def self.spawn(*args)
    projectile = self.new(*args)
    $game_map.add_projectile(projectile)
    yield projectile if block_given?
  end
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(character, type, item)
    super()
    moveto(character.x, character.y)
    @character, @type, @item = character, type, item
    @direction, @battler = character.direction, character.battler
    initialize_projectile
    eval(@initial_effect)
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - collide_with_events?
  #--------------------------------------------------------------------------
  def collide_with_events?(x, y)
    return super unless @battler_through
    $game_map.events_xy_nt(x, y).reject(&:battler).any?(&:normal_priority?)
  end
  #--------------------------------------------------------------------------
  # * New Method - initialize_projectile
  #--------------------------------------------------------------------------
  def initialize_projectile
    attrs = ZABS_Setup::PROJECTILE_DEFAULT.clone
    attrs.merge!(ZABS_Setup::PROJECTILES[@type])
    attrs.each {|k, v| instance_variable_set("@#{k}", v)}
    @ignore = (@ignore.to_s + "?").intern
  end
  #--------------------------------------------------------------------------
  # * New Method - stopping?
  #--------------------------------------------------------------------------
  def stopping?
    @distance.zero? && !moving?
  end
  #--------------------------------------------------------------------------
  # * New Method - valid_targets
  #--------------------------------------------------------------------------
  def valid_targets
    arr = $game_map.entities_xyd(@x, @y, @size) - [self]
    arr.delete(@character) if @ignore == :user?
    arr.reject!(&method(@ignore)) if respond_to?(@ignore)
    return arr
  end
  #--------------------------------------------------------------------------
  # * New Method - chain
  #--------------------------------------------------------------------------
  def chain(type, item)
    self.class.spawn(@character, type, item) do |x|
      x.moveto(@x, @y)
      x.set_direction(@direction)
      yield x if block_given?
    end
  end
  #--------------------------------------------------------------------------
  # * New Method - apply_projectile
  #--------------------------------------------------------------------------
  def apply_projectile(projectile)
    return unless @allow_collision
    eval(projectile.collide_effect)
    process_reflection(projectile) if projectile.reflective
  end
  #--------------------------------------------------------------------------
  # * New Method - process_reflection
  #--------------------------------------------------------------------------
  def process_reflection(projectile)
    turn_180 unless @battler == (@battler = projectile.battler)
  end
  #--------------------------------------------------------------------------
  # * New Method - move_projectile
  #--------------------------------------------------------------------------
  def move_projectile
    return if @distance.zero? || moving?
    @distance -= 1
    move_forward
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
    @transparent = true
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

#============================================================================
# ** New Subclass - Sprite_MapItem
#============================================================================
class Sprite_MapItem < Sprite_Character
  #--------------------------------------------------------------------------
  # * Overwrite Method - update_position
  #--------------------------------------------------------------------------
  def update_position
    super
    self.y += (src_rect.height - 32) / 2
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - setup_new_effect
  #--------------------------------------------------------------------------
  def setup_new_effect
  end
end

#============================================================================
# ** New Subclass - Scene_MapItem
#============================================================================
class Scene_MapItem < Scene_ItemBase
  attr_accessor :item
  #--------------------------------------------------------------------------
  # * Overwrite Method - start
  #--------------------------------------------------------------------------
  def start
    super
    show_sub_window(@actor_window)
    @actor_window.select_last
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - cursor_left?
  #--------------------------------------------------------------------------
  def cursor_left?
    $game_player.screen_x <= Graphics.width / 2
  end
  #--------------------------------------------------------------------------
  # * Overwrite Method - activate_item_window
  #--------------------------------------------------------------------------
  def activate_item_window
    SceneManager.return
  end
  #--------------------------------------------------------------------------
  # * New Method - play_se_for_item
  #--------------------------------------------------------------------------
  def play_se_for_item
    Sound.play_use_item
  end
end
