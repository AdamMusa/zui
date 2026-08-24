import QtQuick
import "../../../Theme"

Item {
    id: chartRoot

    required property var renderer
    required property string chartType
    readonly property string requestedFontFamily: String(renderer.prop("font_family", renderer.fontFamily))

    Text {
        id: fontResolver
        visible: false
        font.family: chartRoot.requestedFontFamily
    }

    function colors() {
        var result = renderer.prop("colors", []);
        return Array.isArray(result) && result.length > 0 ? result : [renderer.prop("color", Color.accent), "#e0af68", "#9ece6a", "#bb9af7", "#f7768e", "#7dcfff"];
    }

    function numericValues() {
        var values = renderer.prop("values", []);
        return Array.isArray(values) ? values.map(function(value) {
            return Number(value && value.value !== undefined ? value.value : value);
        }) : [];
    }

    function bounds(values, requestedMin, requestedMax) {
        var low = renderer.prop(requestedMin, null);
        var high = renderer.prop(requestedMax, null);
        if (low === null)
            low = values.length ? Math.min.apply(Math, values) : 0;

        if (high === null)
            high = values.length ? Math.max.apply(Math, values) : 1;

        low = Number(low);
        high = Number(high);
        if (low === high) {
            low -= 1;
            high += 1;
        }
        return {
            "low": low,
            "high": high
        };
    }

    function pointValue(point, key, index, fallback) {
        if (Array.isArray(point))
            return Number(point[index] === undefined ? fallback : point[index]);

        if (point && typeof point === "object")
            return Number(point[key] === undefined ? fallback : point[key]);

        return Number(fallback);
    }

    function textStyle(ctx, color) {
        ctx.fillStyle = color || renderer.prop("label_color", renderer.foreground);
        var resolvedFamily = String(fontResolver.fontInfo.family || chartRoot.requestedFontFamily);
        ctx.font = Number(renderer.prop("font_size", 12)) + "px " + JSON.stringify(resolvedFamily);
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
    }

    function labelAt(index, fallback) {
        var labels = renderer.prop("labels", []);
        return Array.isArray(labels) && index < labels.length ? String(labels[index]) : String(fallback);
    }

    function drawGrid(ctx, pad) {
        if (renderer.prop("show_grid", true) === false)
            return ;

        ctx.strokeStyle = renderer.prop("grid_color", Qt.rgba(1, 1, 1, 0.15));
        ctx.lineWidth = 1;
        for (var line = 0; line <= 4; line++) {
            var y = pad + (height - 2 * pad) * line / 4;
            ctx.beginPath();
            ctx.moveTo(pad, y);
            ctx.lineTo(width - pad, y);
            ctx.stroke();
        }
    }

    function drawPie(ctx, donut) {
        var values = numericValues();
        var total = values.reduce(function(sum, value) {
            return sum + Math.max(0, value);
        }, 0);
        if (total <= 0)
            return ;

        var palette = colors();
        var cx = width / 2;
        var cy = height / 2;
        var radius = Math.max(1, Math.min(width, height) / 2 - 8);
        var angle = Number(renderer.prop("start_angle", -90)) * Math.PI / 180;
        var direction = renderer.prop("clockwise", true) === false ? -1 : 1;
        var pad = Math.max(0, Number(renderer.prop("pad_angle", 0))) * Math.PI / 180;
        for (var index = 0; index < values.length; index++) {
            var sweep = Math.max(0, values[index]) / total * Math.PI * 2 * direction;
            var edge = pad * direction / 2;
            var start = angle + edge;
            var end = angle + sweep - edge;
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.arc(cx, cy, radius, start, end, direction < 0);
            ctx.closePath();
            ctx.fillStyle = palette[index % palette.length];
            ctx.fill();
            if (renderer.prop("show_labels", false) === true) {
                var middle = angle + sweep / 2;
                chartRoot.textStyle(ctx, renderer.prop("label_color", renderer.foreground));
                ctx.fillText(labelAt(index, values[index]), cx + Math.cos(middle) * radius * 0.7, cy + Math.sin(middle) * radius * 0.7);
            }
            angle += sweep;
        }
        var innerRadius = Number(renderer.prop("inner_radius", donut ? 0.58 : 0));
        if (innerRadius > 0) {
            ctx.beginPath();
            ctx.arc(cx, cy, radius * Math.max(0, Math.min(0.98, innerRadius)), 0, Math.PI * 2);
            ctx.fillStyle = renderer.prop("background", "transparent");
            ctx.globalCompositeOperation = "destination-out";
            ctx.fill();
            ctx.globalCompositeOperation = "source-over";
        }
        if (donut && String(renderer.prop("center_text", "")) !== "") {
            chartRoot.textStyle(ctx, renderer.prop("label_color", renderer.foreground));
            ctx.fillText(String(renderer.prop("center_text", "")), cx, cy);
        }
    }

    function drawLine(ctx, compact) {
        var values = numericValues();
        if (!values.length)
            return ;

        var pad = compact ? 2 : 20;
        var range = bounds(values, "minimum", "maximum");
        if (!compact)
            drawGrid(ctx, pad);

        ctx.beginPath();
        var points = [];
        for (var index = 0; index < values.length; index++) {
            var x = pad + (values.length === 1 ? (width - 2 * pad) / 2 : (width - 2 * pad) * index / (values.length - 1));
            var y = pad + (height - 2 * pad) * (1 - (values[index] - range.low) / (range.high - range.low));
            points.push({
                "x": x,
                "y": y
            });
            if (index === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        var fill = String(renderer.prop("fill_color", "transparent"));
        if (fill !== "" && fill !== "transparent") {
            ctx.lineTo(points[points.length - 1].x, height - pad);
            ctx.lineTo(points[0].x, height - pad);
            ctx.closePath();
            ctx.fillStyle = fill;
            ctx.fill();
            ctx.beginPath();
            for (var pointIndex = 0; pointIndex < points.length; pointIndex++) {
                if (pointIndex === 0)
                    ctx.moveTo(points[pointIndex].x, points[pointIndex].y);
                else
                    ctx.lineTo(points[pointIndex].x, points[pointIndex].y);
            }
        }
        ctx.strokeStyle = renderer.prop("color", Color.accent);
        ctx.lineWidth = Number(renderer.prop("line_width", 2));
        ctx.stroke();
        if (renderer.prop("show_points", false) === true) {
            ctx.fillStyle = renderer.prop("color", Color.accent);
            for (var point = 0; point < points.length; point++) {
                ctx.beginPath();
                ctx.arc(points[point].x, points[point].y, Number(renderer.prop("point_size", 4)), 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }

    function seriesValues() {
        var source = renderer.prop("series", renderer.prop("values", []));
        if (!Array.isArray(source))
            return [];

        if (source.length > 0 && !Array.isArray(source[0]) && !(source[0] && Array.isArray(source[0].values)))
            return [source];

        return source.map(function(series) {
            return series && Array.isArray(series.values) ? series.values : series;
        });
    }

    function drawStacked(ctx) {
        var series = seriesValues();
        if (!series.length)
            return ;

        var count = series.reduce(function(max, values) {
            return Math.max(max, values.length);
        }, 0);
        var totals = [];
        for (var i = 0; i < count; i++) {
            totals[i] = 0;
            for (var s = 0; s < series.length; s++) totals[i] += Math.max(0, Number(series[s][i] || 0))
        }
        var range = bounds(totals, "minimum", "maximum");
        range.low = Math.min(0, range.low);
        var pad = 20;
        drawGrid(ctx, pad);
        var palette = colors();
        var horizontal = String(renderer.prop("orientation", "vertical")) === "horizontal";
        var available = horizontal ? height - pad * 2 : width - pad * 2;
        var slot = available / Math.max(1, count);
        var gap = Math.max(0, Number(renderer.prop("bar_spacing", 4)));
        var stackGap = Math.max(0, Number(renderer.prop("stack_spacing", 0)));
        for (var column = 0; column < count; column++) {
            var cursor = horizontal ? pad : height - pad;
            for (var si = 0; si < series.length; si++) {
                var value = Math.max(0, Number(series[si][column] || 0));
                var amount = (horizontal ? width - pad * 2 : height - pad * 2) * value / Math.max(1e-09, range.high - range.low);
                ctx.fillStyle = palette[si % palette.length];
                if (horizontal) {
                    ctx.fillRect(cursor + stackGap / 2, pad + column * slot + gap / 2, Math.max(1, amount - stackGap), Math.max(1, slot - gap));
                    cursor += amount;
                } else {
                    ctx.fillRect(pad + column * slot + gap / 2, cursor - amount + stackGap / 2, Math.max(1, slot - gap), Math.max(1, amount - stackGap));
                    cursor -= amount;
                }
            }
            chartRoot.textStyle(ctx, renderer.foreground);
            var label = labelAt(column, "");
            if (label !== "")
                ctx.fillText(label, horizontal ? 8 : pad + (column + 0.5) * slot, horizontal ? pad + (column + 0.5) * slot : height - 7);

        }
        if (renderer.prop("legend", false) === true) {
            var definitions = renderer.prop("series", []);
            chartRoot.textStyle(ctx, renderer.foreground);
            ctx.textAlign = "left";
            for (var legendIndex = 0; legendIndex < definitions.length; legendIndex++) {
                var name = definitions[legendIndex] && definitions[legendIndex].name !== undefined ? definitions[legendIndex].name : "Series " + (legendIndex + 1);
                ctx.fillStyle = palette[legendIndex % palette.length];
                ctx.fillRect(pad + legendIndex * 90, 2, 8, 8);
                ctx.fillStyle = renderer.foreground;
                ctx.fillText(String(name), pad + 12 + legendIndex * 90, 6);
            }
        }
    }

    function pointSeries() {
        var source = renderer.prop("series", null);
        if (!Array.isArray(source) || source.length === 0)
            return [renderer.prop("values", [])];

        if (Array.isArray(source[0]))
            return source;

        if (source[0] && Array.isArray(source[0].values))
            return source.map(function(definition) {
            return definition.values;
        });

        return [source];
    }

    function drawPoints(ctx, bubbles) {
        var series = pointSeries();
        var points = [];
        for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) if (Array.isArray(series[seriesIndex])) {
            points = points.concat(series[seriesIndex]);
        }
        if (!points.length)
            return ;

        var xs = points.map(function(p, i) {
            return pointValue(p, "x", 0, i);
        });
        var ys = points.map(function(p) {
            return pointValue(p, "y", 1, 0);
        });
        var xb = bounds(xs, "minimum_x", "maximum_x");
        var yb = bounds(ys, "minimum_y", "maximum_y");
        var pad = 20;
        drawGrid(ctx, pad);
        var palette = colors();
        var rawSizes = points.map(function(point) {
            return pointValue(point, "size", 2, 1);
        });
        var rawMax = Math.max.apply(Math, rawSizes.concat([1]));
        var globalIndex = 0;
        for (var seriesNumber = 0; seriesNumber < series.length; seriesNumber++) {
            var currentSeries = Array.isArray(series[seriesNumber]) ? series[seriesNumber] : [];
            var coordinates = [];
            for (var index = 0; index < currentSeries.length; index++) {
                var point = currentSeries[index];
                var pointX = pointValue(point, "x", 0, globalIndex);
                var pointY = pointValue(point, "y", 1, 0);
                var x = pad + (width - pad * 2) * (pointX - xb.low) / (xb.high - xb.low);
                var y = pad + (height - pad * 2) * (1 - (pointY - yb.low) / (yb.high - yb.low));
                coordinates.push({
                    "x": x,
                    "y": y
                });
                var minimumSize = Number(renderer.prop("minimum_size", 5));
                var maximumSize = Number(renderer.prop("maximum_size", 30));
                var rawSize = pointValue(point, "size", 2, 1);
                var size = bubbles ? minimumSize + (maximumSize - minimumSize) * rawSize / rawMax : Number(renderer.prop("point_size", 5));
                ctx.beginPath();
                ctx.arc(x, y, Math.max(1, size), 0, Math.PI * 2);
                ctx.fillStyle = point && point.color !== undefined ? point.color : palette[seriesNumber % palette.length];
                ctx.fill();
                var label = point && point.label !== undefined ? String(point.label) : labelAt(globalIndex, "");
                if (label !== "") {
                    chartRoot.textStyle(ctx, renderer.foreground);
                    ctx.fillText(label, x, y - size - 8);
                }
                globalIndex++;
            }
            if (!bubbles && renderer.prop("connect_lines", false) === true && coordinates.length > 1) {
                ctx.beginPath();
                for (var lineIndex = 0; lineIndex < coordinates.length; lineIndex++) {
                    if (lineIndex === 0)
                        ctx.moveTo(coordinates[lineIndex].x, coordinates[lineIndex].y);
                    else
                        ctx.lineTo(coordinates[lineIndex].x, coordinates[lineIndex].y);
                }
                ctx.strokeStyle = palette[seriesNumber % palette.length];
                ctx.stroke();
            }
        }
    }

    function drawRadar(ctx) {
        var series = seriesValues();
        if (!series.length)
            return ;

        var count = series.reduce(function(current, values) {
            return Math.max(current, Array.isArray(values) ? values.length : 0);
        }, 0);
        if (count < 3)
            return ;

        var flattened = [];
        for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) for (var valueIndex = 0; valueIndex < series[seriesIndex].length; valueIndex++) flattened.push(Number(series[seriesIndex][valueIndex] || 0))
        var max = Math.max.apply(Math, flattened.concat([1]));
        var levels = Number(renderer.prop("levels", 5));
        var cx = width / 2;
        var cy = height / 2;
        var radius = Math.min(width, height) / 2 - 20;
        ctx.strokeStyle = renderer.prop("grid_color", Qt.rgba(1, 1, 1, 0.2));
        for (var level = 1; level <= levels; level++) {
            ctx.beginPath();
            for (var i = 0; i < count; i++) {
                var a = -Math.PI / 2 + i * Math.PI * 2 / count;
                var r = radius * level / levels;
                if (i === 0)
                    ctx.moveTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r);
                else
                    ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r);
            }
            ctx.closePath();
            ctx.stroke();
        }
        for (var labelIndex = 0; labelIndex < count; labelIndex++) {
            var labelAngle = -Math.PI / 2 + labelIndex * Math.PI * 2 / count;
            var label = labelAt(labelIndex, "");
            if (label !== "") {
                chartRoot.textStyle(ctx, renderer.foreground);
                ctx.fillText(label, cx + Math.cos(labelAngle) * (radius + 10), cy + Math.sin(labelAngle) * (radius + 10));
            }
        }
        var palette = colors();
        var pointSize = Math.max(0, Number(renderer.prop("point_size", 0)));
        for (var radarIndex = 0; radarIndex < series.length; radarIndex++) {
            var values = series[radarIndex];
            ctx.beginPath();
            var radarPoints = [];
            for (var index = 0; index < count; index++) {
                var angle = -Math.PI / 2 + index * Math.PI * 2 / count;
                var valueRadius = radius * Number(values[index] || 0) / max;
                var pointX = cx + Math.cos(angle) * valueRadius;
                var pointY = cy + Math.sin(angle) * valueRadius;
                radarPoints.push({
                    "x": pointX,
                    "y": pointY
                });
                if (index === 0)
                    ctx.moveTo(pointX, pointY);
                else
                    ctx.lineTo(pointX, pointY);
            }
            ctx.closePath();
            ctx.globalAlpha = Number(renderer.prop("fill_opacity", 0.25));
            ctx.fillStyle = palette[radarIndex % palette.length];
            ctx.fill();
            ctx.globalAlpha = 1;
            ctx.strokeStyle = palette[radarIndex % palette.length];
            ctx.lineWidth = Number(renderer.prop("line_width", 2));
            ctx.stroke();
            if (pointSize > 0) {
                ctx.fillStyle = palette[radarIndex % palette.length];
                for (var radarPoint = 0; radarPoint < radarPoints.length; radarPoint++) {
                    ctx.beginPath();
                    ctx.arc(radarPoints[radarPoint].x, radarPoints[radarPoint].y, pointSize, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }
    }

    function drawHeatmap(ctx) {
        var matrix = renderer.prop("values", []);
        if (!Array.isArray(matrix) || !matrix.length)
            return ;

        var flat = [];
        matrix.forEach(function(row) {
            if (Array.isArray(row))
                row.forEach(function(v) {
                flat.push(Number(v));
            });

        });
        var range = bounds(flat, "minimum", "maximum");
        var rows = matrix.length;
        var columns = matrix.reduce(function(max, row) {
            return Math.max(max, Array.isArray(row) ? row.length : 0);
        }, 0);
        var palette = colors();
        var gap = Number(renderer.prop("cell_spacing", 1));
        var xLabels = renderer.prop("x_labels", []);
        var yLabels = renderer.prop("y_labels", []);
        var left = yLabels.length ? 42 : 0;
        var bottom = xLabels.length ? 24 : 0;
        var cellWidth = (width - left) / columns;
        var cellHeight = (height - bottom) / rows;
        for (var y = 0; y < rows; y++) for (var x = 0; x < matrix[y].length; x++) {
            var t = (Number(matrix[y][x]) - range.low) / (range.high - range.low);
            var index = Math.max(0, Math.min(palette.length - 1, Math.floor(t * palette.length)));
            ctx.fillStyle = palette[index];
            ctx.fillRect(left + x * cellWidth + gap / 2, y * cellHeight + gap / 2, cellWidth - gap, cellHeight - gap);
            if (renderer.prop("show_values", false) === true) {
                chartRoot.textStyle(ctx, renderer.prop("value_color", renderer.foreground));
                ctx.fillText(String(matrix[y][x]), left + (x + 0.5) * cellWidth, (y + 0.5) * cellHeight);
            }
        }
        chartRoot.textStyle(ctx, renderer.foreground);
        for (var xi = 0; xi < xLabels.length; xi++) ctx.fillText(String(xLabels[xi]), left + (xi + 0.5) * cellWidth, height - bottom / 2)
        for (var yi = 0; yi < yLabels.length; yi++) ctx.fillText(String(yLabels[yi]), left / 2, (yi + 0.5) * cellHeight)
    }

    function drawGauge(ctx, radial) {
        var values = numericValues();
        var value = values.length ? values[0] : Number(renderer.prop("value", 0));
        var min = Number(renderer.prop("minimum", 0));
        var max = Number(renderer.prop("maximum", 1));
        var t = Math.max(0, Math.min(1, (value - min) / Math.max(1e-09, max - min)));
        var cx = width / 2;
        var cy = height / 2;
        var radius = Math.min(width, height) / 2 - 12;
        var start = Number(renderer.prop("start_angle", radial ? 135 : 180)) * Math.PI / 180;
        var end = Number(renderer.prop("end_angle", radial ? 405 : 360)) * Math.PI / 180;
        var thickness = Number(renderer.prop("thickness", 12));
        ctx.lineWidth = thickness;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.arc(cx, cy, radius, start, end);
        ctx.strokeStyle = renderer.prop("track_color", Qt.rgba(1, 1, 1, 0.15));
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(cx, cy, radius, start, start + (end - start) * t);
        ctx.strokeStyle = renderer.prop("color", Color.accent);
        ctx.stroke();
        if (renderer.prop("show_label", true) !== false) {
            var format = String(renderer.prop("label_format", "%{value}"));
            var text = format.replace("%{value}", String(value)).replace("%{label}", String(renderer.prop("label", "")));
            chartRoot.textStyle(ctx, renderer.foreground);
            ctx.fillText(text, cx, cy);
        }
    }

    function drawHistogram(ctx) {
        var values = numericValues();
        if (!values.length)
            return ;

        var bins = Math.max(1, Number(renderer.prop("bins", Math.ceil(Math.sqrt(values.length)))));
        var range = bounds(values, "minimum", "maximum");
        var counts = new Array(bins).fill(0);
        values.forEach(function(v) {
            var i = Math.min(bins - 1, Math.floor((v - range.low) / (range.high - range.low) * bins));
            counts[Math.max(0, i)]++;
        });
        if (renderer.prop("cumulative", false) === true)
            for (var cumulativeIndex = 1; cumulativeIndex < counts.length; cumulativeIndex++) counts[cumulativeIndex] += counts[cumulativeIndex - 1];

        if (renderer.prop("normalize", false) === true)
            for (var normalizedIndex = 0; normalizedIndex < counts.length; normalizedIndex++) counts[normalizedIndex] /= values.length;

        var max = Math.max.apply(Math, counts);
        var pad = 20;
        drawGrid(ctx, pad);
        var slot = (width - pad * 2) / bins;
        var gap = Math.max(0, Number(renderer.prop("bar_spacing", 2)));
        ctx.fillStyle = colors()[0];
        for (var i = 0; i < bins; i++) {
            var h = (height - pad * 2) * counts[i] / Math.max(1e-09, max);
            ctx.fillRect(pad + i * slot + gap / 2, height - pad - h, Math.max(1, slot - gap), h);
            var label = labelAt(i, "");
            if (label !== "") {
                chartRoot.textStyle(ctx, renderer.foreground);
                ctx.fillText(label, pad + (i + 0.5) * slot, height - 7);
            }
        }
    }

    function drawCandles(ctx) {
        var candles = renderer.prop("values", []);
        if (!Array.isArray(candles) || !candles.length)
            return ;

        var lows = candles.map(function(c) {
            return pointValue(c, "low", 2, 0);
        });
        var highs = candles.map(function(c) {
            return pointValue(c, "high", 1, 1);
        });
        var range = bounds(lows.concat(highs), "minimum", "maximum");
        var pad = 20;
        var py = function py(v) {
            return pad + (height - pad * 2) * (1 - (v - range.low) / (range.high - range.low));
        };
        drawGrid(ctx, pad);
        var slot = (width - pad * 2) / candles.length;
        var spacing = Math.max(0, Number(renderer.prop("candle_spacing", 4)));
        for (var i = 0; i < candles.length; i++) {
            var c = candles[i];
            var open = pointValue(c, "open", 0, 0);
            var high = pointValue(c, "high", 1, open);
            var low = pointValue(c, "low", 2, open);
            var close = pointValue(c, "close", 3, open);
            var x = pad + (i + 0.5) * slot;
            ctx.strokeStyle = renderer.prop("wick_color", renderer.foreground);
            ctx.beginPath();
            ctx.moveTo(x, py(high));
            ctx.lineTo(x, py(low));
            ctx.stroke();
            ctx.fillStyle = close >= open ? renderer.prop("up_color", "#9ece6a") : renderer.prop("down_color", "#f7768e");
            var candleWidth = Math.max(1, slot - spacing);
            ctx.fillRect(x - candleWidth / 2, Math.min(py(open), py(close)), candleWidth, Math.max(1, Math.abs(py(open) - py(close))));
            var label = labelAt(i, "");
            if (label !== "") {
                chartRoot.textStyle(ctx, renderer.foreground);
                ctx.fillText(label, x, height - 7);
            }
        }
    }

    implicitWidth: Number(renderer.prop("width", chartType === "sparkline" ? 160 : 420))
    implicitHeight: Number(renderer.prop("height", chartType === "sparkline" ? 48 : 260))

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            if (chartType === "pie")
                chartRoot.drawPie(ctx, false);
            else if (chartType === "donut")
                chartRoot.drawPie(ctx, true);
            else if (chartType === "stacked_bar")
                chartRoot.drawStacked(ctx);
            else if (chartType === "scatter")
                chartRoot.drawPoints(ctx, false);
            else if (chartType === "bubble")
                chartRoot.drawPoints(ctx, true);
            else if (chartType === "radar")
                chartRoot.drawRadar(ctx);
            else if (chartType === "heatmap")
                chartRoot.drawHeatmap(ctx);
            else if (chartType === "gauge")
                chartRoot.drawGauge(ctx, false);
            else if (chartType === "radial_gauge")
                chartRoot.drawGauge(ctx, true);
            else if (chartType === "histogram")
                chartRoot.drawHistogram(ctx);
            else if (chartType === "candlestick")
                chartRoot.drawCandles(ctx);
            else
                chartRoot.drawLine(ctx, chartType === "sparkline");
        }
    }

    Connections {
        function onNodeChanged() {
            canvas.requestPaint();
        }

        target: renderer
    }

    MouseArea {
        function payload(mouse) {
            var values = renderer.prop("values", []);
            var index = Math.max(0, Math.min(values.length - 1, Math.floor(mouse.x / Math.max(1, width) * values.length)));
            return {
                "x": mouse.x,
                "y": mouse.y,
                "index": index,
                "value": values[index]
            };
        }

        anchors.fill: parent
        hoverEnabled: renderer.subscribed("hover")
        onClicked: function(mouse) {
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "select", payload(mouse));
        }
        onPositionChanged: function(mouse) {
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", payload(mouse));
        }
    }

}
