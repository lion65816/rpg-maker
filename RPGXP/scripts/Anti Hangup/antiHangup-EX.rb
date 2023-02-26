# ===========================================================================
# ★ WF-RGSS Scripts ★
#    antiHangup-EX ハングアップ回避スクリプト(XP専用)
# バージョン   ： rev-1 (2013-3-30)
# 作者         ： WF_RGSS担当 (WHITE-FLUTE)
# サポート先URI： http://www.whiteflute.org/wfrgss/
# ---------------------------------------------------------------------------
# 機能：
# ・RPGツクールXP上にて、ハングアップを回避します。
# ---------------------------------------------------------------------------
# 影響：
# ・この機能が有効な間、処理速度が低下します。
# ---------------------------------------------------------------------------
# 設置場所：Scene_Debugより下、Mainより上
# 必要スクリプト：
# ・共通スクリプト(rev-29以降)、デバッグ修正スクリプト
# 注意事項：
#   共通スクリプトを導入しないとエラーになります。
#  デバッグ修正スクリプトを入れないとデバッグ時に保護できません。
# ===========================================================================
raise "It doesn't correspond to RGSS of this version." if rpgvx?

module AntiHangup
  #--------------------------------------------------------------------------
  # ● モジュール変数
  #--------------------------------------------------------------------------
  @ah = Win32API.new('antiHangup','update','v','v').freeze
  @t = nil
  @start = false
  #--------------------------------------------------------------------------
  # ● ハングアップ回避開始
  #--------------------------------------------------------------------------
  def self.start
    return if @t
    @start = true
    @t = Thread.new do
      @ah.call() while @start
      @t = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● ハングアップ回避終了
  #--------------------------------------------------------------------------
  def self.stop
    @start = false
  end
end

