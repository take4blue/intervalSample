## 1.0.2
Alarm ManagerとTimerで定時処理を切り替えて定時処理を行えるようにする。</br>
また開始・終了の指示をボタンで可能とし、期間(単位は秒)をテキストで設定可能としている。

## 1.0.1
android_alarm_manager_plusとoptimize_batteryを入れてDoze対策。</br>
失敗したけど。

android_alarm_manager_plusをalarmClock: trueで動かすとアプリがKillされる。</br>
設定された関数は呼び出しされているのだろう。</br>
GUI側がKillされ処理がされていなかったので、対策としては失敗。