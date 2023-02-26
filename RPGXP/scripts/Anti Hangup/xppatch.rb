# ===========================================================================
# ★ WF-RGSS Scripts ★
#    デバッグ修正スクリプト(XP専用)
# バージョン   ： rev-1 (2013-3-26)
# 作者         ： WF_RGSS担当 (WHITE-FLUTE)
# サポート先URI： http://www.whiteflute.org/wfrgss/
# ---------------------------------------------------------------------------
# 機能：
# ・RPGツクールXP上にて、デバッグ時にスレッドを使えるようにします。
# ---------------------------------------------------------------------------
# 設置場所：Scene_Debugより下、Mainより上
# 必要スクリプト：
# ・共通スクリプト(rev-29以降)
# 注意事項：
#   共通スクリプトを導入しないとエラーになります。
# ===========================================================================
raise "It doesn't correspond to RGSS of this version." if rpgvx?

class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 通行可能判定 (再定義)
  #--------------------------------------------------------------------------
  def passable?(x, y, d)
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    return false unless $game_map.valid?(new_x, new_y)
    return true if debug? and Input.press?(Input::CTRL)
    super
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新 (再定義)
  #--------------------------------------------------------------------------
  def update
    last_moving = moving?
    update_moving
    last_real_x = @real_x
    last_real_y = @real_y
    super
    update_scroll
    update_encounter_and_event_check( last_moving )
  end
  private
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ 移動制御
  #--------------------------------------------------------------------------
  def update_moving
    unless moving? or $game_system.map_interpreter.running? or
           @move_route_forcing or $game_temp.message_window_showing
      case Input.dir4
      when 2
        move_down
      when 4
        move_left
      when 6
        move_right
      when 8
        move_up
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ スクロール制御
  #--------------------------------------------------------------------------
  def update_scroll
    if @real_y > last_real_y and @real_y - $game_map.display_y > CENTER_Y
      $game_map.scroll_down(@real_y - last_real_y)
    elsif @real_y < last_real_y and @real_y - $game_map.display_y < CENTER_Y
      $game_map.scroll_up(last_real_y - @real_y)
    end
    if @real_x < last_real_x and @real_x - $game_map.display_x < CENTER_X
      $game_map.scroll_left(last_real_x - @real_x)
    elsif @real_x > last_real_x and @real_x - $game_map.display_x > CENTER_X
      $game_map.scroll_right(@real_x - last_real_x)
    end
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ エンカウントとイベントの処理
  #--------------------------------------------------------------------------
  def update_encounter_and_event_check( last_moving )
    unless moving?
      update_encounter( last_moving )
      event_check
    end
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ エンカウントの処理
  #--------------------------------------------------------------------------
  def update_encounter( last_moving )
    if last_moving
      result = check_event_trigger_here([1,2])
      unless result
        unless debug? and Input.press?(Input::CTRL)
          if @encounter_count > 0
            @encounter_count -= 1
          end
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ イベントの処理
  #--------------------------------------------------------------------------
  def event_check
    if Input.trigger?(Input::C)
      check_event_trigger_here([0])
      check_event_trigger_there([0,1,2])
    end
  end
end

class Scene_Map
  private
  #--------------------------------------------------------------------------
  # ● フレーム更新 (再定義)
  #--------------------------------------------------------------------------
  def update
    main_update
    update_goto_scene
    update_transition
    return if $game_temp.message_window_showing
    update_encounter
    update_menu_calling
    update_debug
    update_call_scene
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ 更新処理
  #--------------------------------------------------------------------------
  def main_update
    loop do
      $game_map.update
      $game_system.map_interpreter.update
      $game_player.update
      $game_system.update
      $game_screen.update
      break unless $game_temp.player_transferring
      transfer_player
      break if $game_temp.transition_processing
    end
    @spriteset.update
    @message_window.update
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ シーン直行
  #--------------------------------------------------------------------------
  def update_goto_scene
    if $game_temp.gameover
      $scene = Scene_Gameover.new
      return
    end
    if $game_temp.to_title
      $scene = Scene_Title.new
      return
    end
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ トランジションの処理
  #--------------------------------------------------------------------------
  def update_transition
    if $game_temp.transition_processing
      $game_temp.transition_processing = false
      if $game_temp.transition_name == ""
        Graphics.transition(20)
      else
        Graphics.transition(40, "Graphics/Transitions/" +
          $game_temp.transition_name)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ エンカウントの処理
  #--------------------------------------------------------------------------
  def update_encounter
    if $game_player.encounter_count == 0 and $game_map.encounter_list != []
      unless $game_system.map_interpreter.running? or
             $game_system.encounter_disabled
        n = rand($game_map.encounter_list.size)
        troop_id = $game_map.encounter_list[n]
        if $data_troops[troop_id]
          $game_temp.battle_calling = true
          $game_temp.battle_troop_id = troop_id
          $game_temp.battle_can_escape = true
          $game_temp.battle_can_lose = false
          $game_temp.battle_proc = nil
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ メニュー遷移
  #--------------------------------------------------------------------------
  def update_menu_calling
    if Input.trigger?(Input::B)
      unless $game_system.map_interpreter.running? or
             $game_system.menu_disabled
        $game_temp.menu_calling = true
        $game_temp.menu_beep = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ デバッグ遷移
  #--------------------------------------------------------------------------
  def update_debug
    $game_temp.debug_calling = true if debug? and Input.press?(Input::F9)
  end
  #--------------------------------------------------------------------------
  # ◆(内部専用)◆ シーン呼び出し
  #--------------------------------------------------------------------------
  def update_call_scene
    unless $game_player.moving?
      if $game_temp.battle_calling
        call_battle
      elsif $game_temp.shop_calling
        call_shop
      elsif $game_temp.name_calling
        call_name
      elsif $game_temp.menu_calling
        call_menu
      elsif $game_temp.save_calling
        call_save
      elsif $game_temp.debug_calling
        call_debug
      end
    end
  end
end
