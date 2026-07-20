extends Node

const ASSETS = {
    "blacksmith": preload("res://scenes/adeeb_assets/blacksmith.tscn"),
    "mimic": preload("res://scenes/adeeb_assets/mimic.tscn"),
    "minotaur": preload("res://scenes/adeeb_assets/minotaur.tscn"),
    "props": preload("res://scenes/adeeb_assets/props.tscn"),
    "player_sprite": preload("res://scenes/adeeb_assets/player_equipment/player_sprite.tscn"),
    "player_sprite_ninja_suit": preload("res://scenes/adeeb_assets/player_equipment/player_sprite_ninja_suit.tscn"),
    "player_sprite_sword": preload("res://scenes/adeeb_assets/player_equipment/player_sprite_sword.tscn"),
    "player_sprite_sword_katana": preload("res://scenes/adeeb_assets/player_equipment/player_sprite_sword_katana.tscn"),
    "gear": preload("res://scenes/adeeb_assets/player_equipment/gear.tscn"),
    "equip_sound": preload("res://scenes/adeeb_assets/player_equipment/equip_sound.tscn"),
    "shopkeeper": preload("res://scenes/adeeb_assets/shopkeeper/shopkeeper.tscn"),
    "fishbowl": preload("res://scenes/adeeb_assets/shopkeeper/fishbowl.tscn"),
    "shop": preload("res://scenes/adeeb_assets/shopkeeper/shop.tscn"),
    "portrait_placeholder": preload("res://scenes/adeeb_assets/shopkeeper/portrait_placeholder.tscn"),
    "shop_open": preload("res://scenes/adeeb_assets/shopkeeper/shop_open.tscn"),
    "error_sound": preload("res://scenes/adeeb_assets/shopkeeper/error_sound.tscn"),
    "purchase_sound": preload("res://scenes/adeeb_assets/shopkeeper/purchase_sound.tscn"),
}

static func instantiate_asset(name: String) -> Node2D:
    if not ASSETS.has(name):
        return null
    return ASSETS[name].instantiate() as Node2D

static func asset_names() -> Array:
    return ASSETS.keys()
