import QtQuick
import qs.Commons as Commons
import "Model.js" as Model

Canvas {
    id: surface
    property string shape: "circle"
    property int count: 6
    property int selection: -1
    property color background: Commons.Color.menu.background
    property color ink: Commons.Color.menu.text
    property color selectedFill: Commons.Color.menu.selectedBackground
    property color selectedOutline: Commons.Color.menu.selectedBorder
    antialiasing: true
    onAvailableChanged: if (available)
                            requestPaint()
    onVisibleChanged: if (visible)
                          requestPaint()
    onShapeChanged: requestPaint()
    onCountChanged: requestPaint()
    onSelectionChanged: requestPaint()
    onBackgroundChanged: requestPaint()
    onInkChanged: requestPaint()
    onSelectedFillChanged: requestPaint()
    onSelectedOutlineChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var c = getContext("2d");
        c.reset();
        if (width <= 0 || height <= 0)
            return;
        var center = width / 2, polygon = shape === "polygon" && count >= 3;
        var step = Math.PI * 2 / Math.max(1, count), gap = Math.PI / 180;
        function point(angle, radius, first) {
            var x = center + Math.cos(angle) * radius, y = center + Math.sin(angle) * radius;
            if (first)
                c.moveTo(x, y);
            else
                c.lineTo(x, y);
        }
        function outer(start, middle, end, radius, first) {
            if (polygon) {
                point(start, Model.edgeRadius(start, width, count, shape, radius), first);
                point(middle, width * radius, false);
                point(end, Model.edgeRadius(end, width, count, shape, radius), false);
            } else {
                if (first)
                    point(start, width * radius, true);
                c.arc(center, center, width * radius, start, end);
            }
        }
        c.lineWidth = 1;
        c.beginPath();
        if (polygon) {
            for (var vertex = 0; vertex < count; vertex++)
                point(vertex * step - Math.PI / 2, width * 0.49, vertex === 0);
            c.closePath();
        } else
            c.arc(center, center, width * 0.49, 0, Math.PI * 2);
        c.fillStyle = background;
        c.fill();
        c.strokeStyle = Commons.Util.alpha(ink, 0.25);
        c.stroke();
        for (var i = 0; i < count; i++) {
            var middle = i * step - Math.PI / 2;
            var start = middle - step / 2 + gap, end = middle + step / 2 - gap;
            c.beginPath();
            outer(start, middle, end, 0.48, true);
            c.arc(center, center, width * 0.18, end, start, true);
            c.closePath();
            c.fillStyle = i === selection ? selectedFill : background;
            c.fill();
            c.strokeStyle = i === selection ? selectedOutline : Commons.Util.alpha(ink, 0.23);
            c.stroke();
            if (i === selection) {
                c.beginPath();
                outer(start + 0.025, middle, end - 0.025, 0.48 - 3 / width, true);
                c.strokeStyle = selectedOutline;
                c.lineWidth = 3;
                c.stroke();
                c.lineWidth = 1;
            }
        }
    }
}
