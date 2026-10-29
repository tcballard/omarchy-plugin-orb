import QtQuick
import qs.Commons as Commons
import qs.Ui

Button {
    focusable: true
    implicitHeight: Math.max(48, Commons.Style.space(40))
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: if (enabled) clicked()
    bordered: true
    foreground: Commons.Color.menu.text
    fontFamily: Commons.Style.font.menuFamily
    fontSize: Commons.Style.space(12)
}
