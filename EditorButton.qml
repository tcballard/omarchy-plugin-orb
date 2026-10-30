import QtQuick
import qs.Commons as Commons
import qs.Ui

Button {
    focusable: true
    bordered: true
    foreground: Commons.Color.menu.text
    fontFamily: Commons.Style.font.menuFamily
    fontSize: Commons.Style.space(12)
}
