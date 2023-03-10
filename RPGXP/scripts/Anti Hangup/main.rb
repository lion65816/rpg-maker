# coding: utf-8
# ===========================================================================
# ★ WF-RGSS Scripts ★
#    共通実行スクリプト(XP/VX/VXAce両対応版)
# バージョン   ： rev-29 (2013-3-26)
# 作者         ： WF_RGSS担当 (WHITE-FLUTE)
# サポート先URI： http://www.whiteflute.org/wfrgss/
# ---------------------------------------------------------------------------
# 機能：
# ・デバッグモードで例外が発生したとき、エラーを errors.txt に記録します。
# ・高速なリセットを利用できるようになります。
# ---------------------------------------------------------------------------
# 影響：
# ・ファイルが見つからない例外は、 元の Errno::ENOENT が補足されます。
# ---------------------------------------------------------------------------
# 設置場所     ：Mainセクション(一番最後)に上書き
#                または、Mainセクションの直前
# 必要スクリプト：
# ・共通スクリプト
# 注意事項：
# ▽ 共通スクリプトが必要です。
#    改造して使用することを推奨しますが、そのまま使ってもOKです。
# ▽ デバッグモードでエラーを記録する場合、
#    現在のユーザで書き込みを行えることが必要になります。
#==============================================================================
# ◆ Main ( Execute )
#------------------------------------------------------------------------------
# 　各クラスの定義が終わった後、ここから実際の処理が始まります。
#==============================================================================

# ---------------------------------------------------------------------------
# ◆ 処理実行
# ---------------------------------------------------------------------------
# スレッド例外で即座に中断しないようにする。(デバッグ時は無効)
# ※ true に設定する場合はご注意ください。
#    終了する前に解放が必要なものもあります。
Thread.abort_on_exception = false
# RPGVX 互換
if rpgvx? and (not rpgvxace?)
  unless Font.exist?("UmePlus Gothic")
    print "UmePlus Gothic フォントが見つかりません。"
    exit
  end
end

begin
  unless rpgvxace?
    # トランジション準備
    Graphics.freeze
    # シーンオブジェクトを作成
    # ★ 最初のシーンはここに設定します。 ★

    $scene = Scene_Title.new

    # ★ --------------------------------------------------------------------
    # $scene が有効な限り main メソッドを呼び出す
    $scene.main until $scene.nil?
    # フェードアウト
    Graphics.transition(20)
 
  else
    rgss_main { SceneManager.run }
  end
    # 以下、例外処理
rescue BugDetected, InternalBugDetected => errobj
  begin
    MessageBox.fatalerror( errobj )
    raise SystemExit.new(1)
  rescue Hangup
    nil
  end

rescue Reset
  # -------------------------------------------------------------------------
  # ◆ F12 リセット( 例外 Reset < Exception )
  # -------------------------------------------------------------------------
  # ※retry する場合は、
  #   かならず、ウィンドウやスプライトが確実に解放される必要があります。
  # ※ RGSS2環境ではF12の機構を封じないと封じ込められません。
  
  raise
rescue Hangup => errobj
  # -------------------------------------------------------------------------
  # ◆ 致命的例外 Hangup
  # -------------------------------------------------------------------------
  begin
    MessageBox.fatalerror( errobj )
    raise SystemExit.new(1)
  rescue Hangup
    nil
  end
rescue SystemExit => errobj
  # -------------------------------------------------------------------------
  # ◆ 終了要求 ( Alt + F4 など )
  # -------------------------------------------------------------------------
  # 例外が正常終了で無い場合は、例外 SystemExitを再発生させます。
  raise unless (errobj.status).zero?

rescue Exception => errobj
  # -------------------------------------------------------------------------
  # ◆ 例外処理
  # 特に指定されていない例外を補足します。
  # ※ rev-2 より、Errno::ENOENT もここで補足します。
  # -------------------------------------------------------------------------
  begin
    MessageBox.fatalerror( errobj )
    raise SystemExit.new(1)
  rescue Hangup
    nil
  end

ensure
  unless $!.is_a?(Reset)
  # -------------------------------------------------------------------------
  # ● 後処理
  # -------------------------------------------------------------------------
  # 後処理を記述します。
  # スクリプト内容によってはここで解放処理が必要になることがあります。
  # ★ 後処理を記述します。 ★


  # ★ ----------------------------------------------------------------------
  else
    $! = nil unless rpgvxace?
  end
end

exit # Mainセクションが後に控えている時に処理が渡らないようにする
