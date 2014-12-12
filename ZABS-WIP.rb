#============================================================================
# ** Start of configuration
#============================================================================
module ZABS_Setup
#----------------------------------------------------------------------------
  PROJECTILES = { # Do not delete this line.
#----------------------------------------------------------------------------
    1 => { # Boulder
      character_name: "!Other1",
      distance: 10,
      knockback: 1,
      piercing: 5,
      initial_effect: %(RPG::SE.new("Earth9", 80).play; jump(0, 0)),
      hit_effect: %(@animation_id = 111),
    },
    2 => { # Arrow
      character_name: "$Arrow",
      move_speed: 6,
      distance: 10,
      knockback: 1,
      initial_effect: %(RPG::SE.new("Bow2", 80).play),
      hit_effect: %(@animation_id = 111),
    },
    3 => { # Bomb
      character_name: "!Other1",
      character_index: 1,
      distance: 10,
      initial_effect: %(RPG::SE.new("Earth9", 80).play),
      hit_effect: %(@hit_cooldown = 0),
      end_effect: %(chain(4, $data_skills[128])),
    },
    4 => { # Explosion
      allow_collision: false,
      size: 4,
      distance: 0,
      ignore: :none,
      initial_effect: %(@animation_id = 113),
    },
#----------------------------------------------------------------------------
  } # Do not delete this line.
#----------------------------------------------------------------------------
  HIT_COOLDOWN_TIME = 30
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
#----------------------------------------------------------------------------
# * Advanced Settings
#----------------------------------------------------------------------------
  PROJECTILE_DEFAULT = {
    move_speed: 5,
    hit_jump: true,
    battler_through: true,
    allow_collision: true,
    reflective: false,
    size: 1,
    distance: 1,
    knockback: 0,
    piercing: 0,
    ignore: :user,
    initial_effect: %(),
    update_effect: %(),
    collide_effect: %(),
    hit_effect: %(),
    end_effect: %(),
  }
  SELF_ITEM_USAGE = true
  MISS_EFFECT = %(RPG::SE.new("Miss", 80).play)
  EVADE_EFFECT = %(RPG::SE.new("Miss", 80).play)
  KEY_MAP_EXTRA = {COMMA: 0xBC, PERIOD: 0xBE}
#----------------------------------------------------------------------------
# * Regular Expressions
#----------------------------------------------------------------------------
  BATTLE_TAGS_REGEX = /<battle[ _]tags:\s*(.*)>/i
  PROJECTILE_REGEX = /<projectile:\s*(\d+)/i
  COOLDOWN_REGEX = /<cooldown:\s*(\d+)/i
  EFFECT_ITEM_REGEX = /<effect[ _]item:\s*(skill|item)\s+(\d+)>/i
  IMMOVABLE_REGEX = /<immovable>/i
  EVADE_JUMP_REGEX = /<evade[ _]jump>/i
  SIZE_REGEX = /<size:\s*(\d+)/i
  HIT_EFFECT_REGEX = /<hit[ _]effect>(.*)<\/hit[ _]effect>/im
  DEATH_EFFECT_REGEX = /<death[ _]effect>(.*)<\/death[ _]effect>/im
  RESPAWN_TIME_REGEX = /<respawn[ _]time:\s*(\d+)>/i
  RESPAWN_EFFECT_REGEX = /<respawn[ _]effect>(.*)<\/respawn[ _]effect>/im
  ENEMY_REGEX = /<enemy:\s*(\d+)>/i
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
  # * New Class Method - update
  #--------------------------------------------------------------------------
  def self.update
    @key_map.each do |k, v|
      state = GetKeyState.call(v) >> 8
      state.zero? ? @key_states[k] = 0 : @key_states[k] += 1
    end
  end
  #--------------------------------------------------------------------------
  # * New Class Method - pressed?
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
  # * New Method - projectile
  #--------------------------------------------------------------------------
  def projectile
    return @projectile if @projectile
    match = @note[ZABS_Setup::PROJECTILE_REGEX, 1]
    @projectile = match ? match.to_i : -1
  end
  #--------------------------------------------------------------------------
  # * New Method - cooldown
  #--------------------------------------------------------------------------
  def cooldown
    @cooldown ||= @note[ZABS_Setup::COOLDOWN_REGEX, 1].to_i
  end
  #--------------------------------------------------------------------------
  # * New Method - effect_item
  #--------------------------------------------------------------------------
  def effect_item
    match = @note.scan(ZABS_Setup::EFFECT_ITEM_REGEX).to_a.flatten
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
    @immovable ||= @note =~ ZABS_Setup::IMMOVABLE_REGEX
  end
  #--------------------------------------------------------------------------
  # * New Method - evade_jump?
  #--------------------------------------------------------------------------
  def evade_jump?
    @evade_jump ||= @note =~ ZABS_Setup::EVADE_JUMP_REGEX
  end
  #--------------------------------------------------------------------------
  # * New Method - size
  #--------------------------------------------------------------------------
  def size
    return @size if @size
    match = @note[ZABS_Setup::SIZE_REGEX, 1].to_i
    @size = match > 0 ? match : 1
  end
  #--------------------------------------------------------------------------
  # * New Method - hit_effect
  #--------------------------------------------------------------------------
  def hit_effect
    @hit_effect ||= @note[ZABS_Setup::HIT_EFFECT_REGEX, 1].to_s
  end
  #--------------------------------------------------------------------------
  # * New Method - death_effect
  #--------------------------------------------------------------------------
  def death_effect
    @death_effect ||= @note[ZABS_Setup::DEATH_EFFECT_REGEX, 1].to_s
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
    match = @note.scan(ZABS_Setup::BATTLE_TAGS_REGEX).to_a
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
    match = @note[ZABS_Setup::RESPAWN_TIME_REGEX, 1].to_i
    @respawn_time = match > 0 ? match : -1
  end
  #--------------------------------------------------------------------------
  # * New Method - respawn_effect
  #--------------------------------------------------------------------------
  def respawn_effect
    @respawn_effect ||= @note[ZABS_Setup::RESPAWN_EFFECT_REGEX, 1].to_s
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
    return (@end_turn_time -= 1) unless @end_turn_time.zero?
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
    $game_map.entities.select {|x| ally?(x)}
  end
  #--------------------------------------------------------------------------
  # * New Method - friends
  #--------------------------------------------------------------------------
  def friends
    $game_map.entities.select {|x| friend?(x)}
  end
  #--------------------------------------------------------------------------
  # * New Method - enemies
  #--------------------------------------------------------------------------
  def enemies
    $game_map.entities.reject {|x| enemy?(x)}
  end
end

#============================================================================
# ** New Module - ZABS_Character
#============================================================================
module ZABS_Character
  include ZABS_Entity
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
    @hit_cooldown = ZABS_Setup::HIT_COOLDOWN_TIME
    battler.item_apply(projectile.battler, projectile.item.effect_item)
    battler.result.hit? ? process_hit(projectile) : process_miss
  end
  #--------------------------------------------------------------------------
  # * New Method - process_hit
  #--------------------------------------------------------------------------
  def process_hit(projectile)
    eval(battler.data.hit_effect)
    projectile.piercing -= 1
    eval(projectile.hit_effect)
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
    return false unless item && @item_cooldown[item].zero?
    return super(item.effect_item)
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
  attr_reader :projectiles, :projectile_sprite_queue
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
  # * New Method - entities
  #--------------------------------------------------------------------------
  def entities
    @events.values.select(&:battler).concat(@projectiles).push($game_player)
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
    return true if item.is_a?(RPG::UsableItem) && item.for_allies?
    return super
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
  # * Overwrite Method - draw_hud?
  #--------------------------------------------------------------------------
  def draw_hud?
    @battler && @battler.alive? && (@battler.hp < @battler.mhp)
  end
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
    return if @battler && @battler.dead?
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
    @battler = Game_MapEnemy.new(enemy_id)
    @respawn_time = @battler.data.respawn_time
    @item_drop = nil
  end
  #--------------------------------------------------------------------------
  # * New Method - enemy_id
  #--------------------------------------------------------------------------
  def enemy_id
    @enemy_id ||= @event.name[ZABS_Setup::ENEMY_REGEX, 1].to_i
  end
  #--------------------------------------------------------------------------
  # * New Method - hp_rate
  #--------------------------------------------------------------------------
  def hp_rate
    @battler.hp.to_f / @battler.mhp
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
    eval(@battler.data.death_effect)
    @item_drop ||= Game_MapItemDrop.spawn(self)
    @opacity > 0 ? @opacity -= ZABS_Setup::DEATH_FADE_RATE : erase
  end
  #--------------------------------------------------------------------------
  # * New Method - process_respawn
  #--------------------------------------------------------------------------
  def process_respawn
    return if @respawn_time == -1
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
  # * New Method - update_battler
  #--------------------------------------------------------------------------
  def update_battler
    return unless @battler
    @battler.update
    update_death
  end
end

#============================================================================
# ** Reopen Class - Sprite_Character
#============================================================================
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # * Alias Method - update
  #--------------------------------------------------------------------------
  alias zabs_sprite_character_update update
  def update
    zabs_sprite_character_update
    setup_hud
    update_hud
  end
  #--------------------------------------------------------------------------
  # * Alias Method - dispose
  #--------------------------------------------------------------------------
  alias zabs_sprite_character_dispose dispose
  def dispose
    dispose_hud
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
    data = ZABS_Setup::HUD_FRONT_COLORS
    level = (data.keys.max * @character.hp_rate).ceil
    return Color.new(*data[level])
  end
  #--------------------------------------------------------------------------
  # * New Method - setup_hud
  #--------------------------------------------------------------------------
  def setup_hud
    return unless @character.draw_hud? && @hud_sprite.nil?
    @hud_sprite = Sprite.new(viewport)
    @hud_sprite.bitmap = Bitmap.new(hud_width, 4)
  end
  #--------------------------------------------------------------------------
  # * New Method - dispose_hud
  #--------------------------------------------------------------------------
  def dispose_hud
    return unless @hud_sprite
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
  def update_hud_bar_width
    return if @last_hp_rate == (@last_hp_rate = @character.hp_rate)
    @hud_sprite.bitmap.fill_rect(0, 0, hud_width, 4, hud_back_color)
    @hud_sprite.bitmap.fill_rect(1, 1, hud_bar_width, 2, hud_front_color)
  end
  #--------------------------------------------------------------------------
  # * New Method - update_hud
  #--------------------------------------------------------------------------
  def update_hud
    return unless @hud_sprite
    return @hud_sprite.bitmap.clear unless @character.draw_hud?
    update_hud_position
    update_hud_bar_width
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
    $game_map.projectiles.select(&:need_sprite).each do |x|
      @character_sprites.push(Sprite_Character.new(@viewport1, x))
      x.need_sprite = false
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
class Scene_Map
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
  # * Overwrite Method - consume_item
  #--------------------------------------------------------------------------
  def consume_item(item)
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

#============================================================================
# ** New Subclass - Game_Projectile
#============================================================================
class Game_Projectile < Game_Character
  include ZABS_Entity
  attr_accessor :piercing, :need_sprite, :need_dispose
  attr_reader :type, :battler, :item, :hit_jump, :reflective, :knockback
  attr_reader :size, :hit_effect, :collide_effect
  #--------------------------------------------------------------------------
  # * New Class Method - spawn
  #--------------------------------------------------------------------------
  def self.spawn(*args)
    projectile = self.new(*args)
    $game_map.add_projectile(projectile)
    return projectile
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
    attrs = ZABS_Setup::PROJECTILE_DEFAULT.merge(data)
    attrs.each {|k, v| instance_variable_set("@#{k}", v)}
    @ignore = (@ignore.to_s + "?").intern
    @need_sprite = true
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
    arr = $game_map.entities_xyd(@x, @y, @size) - [self]
    arr.delete(@character) if @ignore == :user?
    arr.reject!(&method(@ignore)) if respond_to?(@ignore)
    return arr
  end
  #--------------------------------------------------------------------------
  # * New Method - chain
  #--------------------------------------------------------------------------
  def chain(type, item)
    Game_Projectile.spawn(@character, type, item).moveto(@x, @y)
  end
  #--------------------------------------------------------------------------
  # * New Method - apply_projectile
  #--------------------------------------------------------------------------
  def apply_projectile(projectile)
    return unless @allow_collision
    eval(projectile.collide_effect)
    process_reflection(projectile)
  end
  #--------------------------------------------------------------------------
  # * New Method - process_reflection
  #--------------------------------------------------------------------------
  def process_reflection(projectile)
    return unless projectile.reflective && @battler != projectile.battler
    @battler = projectile.battler
    turn_180
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

#============================================================================
# ** New Class - Game_MapItemDrop
#============================================================================
class Game_MapItemDrop
  attr_accessor :need_sprite
  attr_reader :item_drops, :need_dispose
  #--------------------------------------------------------------------------
  # * New Class Method - spawn
  #--------------------------------------------------------------------------
  def self.spawn(*args) # TEMP
    map_item_drop = self.new(*args)
  end
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(character)
    @x, @y = character.x, character.y
    @battler_data = character.battler.data
    @item_drops = random_item_drops
    @need_sprite = true
  end
  #--------------------------------------------------------------------------
  # * New Method - exp
  #--------------------------------------------------------------------------
  def exp
    @battler_data.exp
  end
  #--------------------------------------------------------------------------
  # * New Method - gold
  #--------------------------------------------------------------------------
  def gold
    @battler_data.gold
  end
  #--------------------------------------------------------------------------
  # * New Method - item_object
  #--------------------------------------------------------------------------
  def item_object(type, id)
    arr = case type
    when 1 then $data_items
    when 2 then $data_weapons
    when 3 then $data_armors
    else []
    end
    return arr[id]
  end
  #--------------------------------------------------------------------------
  # * New Method - random_item_drops
  #--------------------------------------------------------------------------
  def random_item_drops
    arr = @battler_data.drop_items.select {|x| rand * x.denominator < 1}
    arr.map {|x| item_object(x.kind, x.data_id)}.compact
  end
end
