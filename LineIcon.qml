import QtQuick

Canvas {
    id: icon
    property string name: "browser"
    property color ink: "white"
    onNameChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    antialiasing: true
    onPaint: {
        var c = getContext("2d"); c.reset();
        c.scale(width / 24, height / 24);
        c.strokeStyle = ink; c.fillStyle = ink; c.lineWidth = 1.6;
        c.lineCap = "round"; c.lineJoin = "round";
        function line(points) { c.beginPath(); c.moveTo(points[0], points[1]); for (var i = 2; i < points.length; i += 2) c.lineTo(points[i], points[i+1]); c.stroke(); }
        function circle(x,y,r) { c.beginPath(); c.arc(x,y,r,0,Math.PI*2); c.stroke(); }
        if (name === "arrow-undo") {
            line([8,4,3,9,8,14]);
            c.beginPath(); c.moveTo(3,9); c.lineTo(14,9);
            c.bezierCurveTo(23,9,23,20,14,20); c.stroke();
        } else if (name === "search") {
            circle(10,10,7); line([15,15,21,21]);
        } else if (name === "link") {
            c.beginPath(); c.moveTo(10,14); c.lineTo(14,10); c.stroke();
            c.beginPath(); c.moveTo(8,16); c.lineTo(6,18); c.bezierCurveTo(1,22,0,16,4,12); c.lineTo(8,8); c.bezierCurveTo(10,6,12,6,14,8); c.stroke();
            c.beginPath(); c.moveTo(16,8); c.lineTo(18,6); c.bezierCurveTo(23,2,24,8,20,12); c.lineTo(16,16); c.bezierCurveTo(14,18,12,18,10,16); c.stroke();
        } else if (name === "code") {
            line([8,6,2,12,8,18]); line([16,6,22,12,16,18]); line([14,3,10,21]);
        } else if (name === "calendar") {
            c.strokeRect(3,5,18,16); line([3,10,21,10]); line([7,2,7,7]); line([17,2,17,7]); line([7,14,9,14]); line([13,14,15,14]); line([7,18,9,18]);
        } else if (name === "clock") {
            circle(12,12,9); line([12,6,12,12,17,15]);
        } else if (name === "mail") {
            c.strokeRect(2,5,20,14); line([2,6,12,13,22,6]);
        } else if (name === "lock") {
            c.strokeRect(5,10,14,11); c.beginPath(); c.arc(12,10,5,Math.PI,0); c.stroke(); line([12,14,12,17]);
        } else if (name === "power") {
            line([12,2,12,12]); c.beginPath(); c.arc(12,12,9,-Math.PI/3, -2*Math.PI/3); c.stroke();
        } else if (name === "cloud") {
            c.beginPath(); c.moveTo(6,19); c.bezierCurveTo(0,19,0,11,6,10); c.bezierCurveTo(7,3,17,3,18,10); c.bezierCurveTo(24,10,24,19,18,19); c.closePath(); c.stroke();
        } else if (name === "bookmark") {
            line([6,3,18,3,18,21,12,17,6,21,6,3]);
        } else if (name === "browser") {
            circle(12,12,9); line([3,12,21,12]);
            c.beginPath(); c.ellipse(8,3,8,18); c.stroke();
        } else if (name === "terminal") {
            c.strokeRect(2.5,4,19,16); line([6,9,9,12,6,15]); line([12,15,17,15]);
        } else if (name === "files") {
            line([3,20,3,5,9,5,11,8,21,8,21,20,3,20]); line([3,11,21,11]);
        } else if (name === "home") {
            line([2,11,12,3,22,11]); line([5,9,5,21,10,21,10,15,14,15,14,21,19,21,19,9]);
        } else if (name === "recent") {
            circle(12,12,9); line([12,6,12,12,16,14]);
        } else if (name === "starred") {
            var points = [];
            for (var i = 0; i <= 10; i++) {
                var angle = (i * 36 - 90) * Math.PI / 180, radius = i % 2 ? 4 : 10;
                points.push(12 + Math.cos(angle) * radius, 12 + Math.sin(angle) * radius);
            }
            line(points);
        } else if (name === "downloads") {
            line([12,3,12,15]); line([7,10,12,15,17,10]); line([3,16,3,21,21,21,21,16]);
        } else if (name === "documents") {
            line([5,2,14,2,20,8,20,22,5,22,5,2]); line([14,2,14,8,20,8]); line([8,12,16,12]); line([8,17,16,17]);
        } else if (name === "pictures") {
            c.strokeRect(3,3,18,18); circle(16,8,2); line([3,18,9,11,14,17,17,14,21,18]);
        } else if (name === "music") {
            line([9,18,9,5,20,2,20,15]); circle(6,18,3); circle(17,15,3); line([9,9,20,6]);
        } else if (name === "videos") {
            c.strokeRect(2,4,20,16); line([10,8,16,12,10,16,10,8]);
        } else if (name === "trash") {
            line([3,6,21,6]); line([9,6,9,3,15,3,15,6]); line([5,6,6,21,18,21,19,6]); line([10,10,10,17]); line([14,10,14,17]);
        } else if (name === "screenshot") {
            line([8,3,3,3,3,8]); line([16,3,21,3,21,8]);
            line([3,16,3,21,8,21]); line([21,16,21,21,16,21]); c.strokeRect(7,7,10,10);
        } else if (name === "postcard") {
            c.strokeRect(2.5,4,19,16); circle(16,8,1.5); line([3,17,8,10,13,16,16,13,21,18]);
        } else if (name === "create") {
            line([10,3,12,9,18,11,12,13,10,19,8,13,2,11,8,9,10,3]);
            line([19,2,20,5,23,6,20,7,19,10,18,7,15,6,18,5,19,2]);
        } else if (name === "app") {
            c.strokeRect(3,3,7,7); c.strokeRect(14,3,7,7); c.strokeRect(3,14,7,7); c.strokeRect(14,14,7,7);
        } else if (name === "themes") {
            circle(12,12,9); circle(8,9,1); circle(13,7,1); circle(17,11,1);
            line([6,17,11,12,16,17]);
        } else if (name === "agents") {
            c.strokeRect(4,7,16,13); line([12,3,12,7]); circle(12,3,1);
            circle(8,12,1); circle(16,12,1); line([9,17,15,17]);
        } else if (name === "settings") {
            line([3,6,21,6]); line([3,12,21,12]); line([3,18,21,18]);
            c.fillStyle = ink; c.fillRect(7,3,3,6); c.fillRect(15,9,3,6); c.fillRect(8,15,3,6);
        } else {
            line([3,9,9,9,9,4,15,4,15,9,21,9,21,15,16,15,16,21,9,21,9,15,3,15,3,9]);
        }
    }
}
