import QtQuick
import qs.Commons as Commons
import qs.Ui

Button {
    focusable: true
    bordered: true
    foreground: Commons.Color.menu.text
    fontFamily: Commons.Style.font.menuFamily
    fontSize: Math.max(14, Commons.Style.space(14))
    implicitHeight: Math.max(48, Commons.Style.space(48))
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: if (enabled) clicked()
}
