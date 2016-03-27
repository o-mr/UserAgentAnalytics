var COLORS = [
  "#f44336",
  "#2196F3",
  "#4CAF50",
  "#FFC107",
  "#E91E63",
  "#3F51B5",
  "#009688",
  "#FF5722",
  "#9C27B0",
  "#00BCD4",
  "#CDDC39",
  "#795548"
];

var options = {
    // 値を区切る線の表示
    segmentShowStroke : true,
    // 値を区切る線の色
    segmentStrokeColor : "#fff",
    // 値を区切る線の幅
    segmentStrokeWidth : 1,
    // 表示の時のアニメーション
    animation : true,
    // アニメーションの速度 ( ステップ数 )
    animationSteps : 60,
    // アニメーションの種類, 以下が用意されている
    // linear, easeInQuad, easeOutQuad, easeInOutQuad, easeInCubic, easeOutCubic,
    // easeInOutCubic, easeInQuart, easeOutQuart, easeInOutQuart, easeInQuint,
    // easeOutQuint, easeInOutQuint, easeInSine, easeOutSine, easeInOutSine,
    // easeInExpo, easeOutExpo, easeInOutExpo, easeInCirc, easeOutCirc, easeInOutCirc,
    // easeInElastic, easeOutElastic, easeInOutElastic, easeInBack, easeOutBack,
    // easeInOutBack, easeInBounce, easeOutBounce, easeInOutBounce
    animationEasing : "easeOutQuad",
    // 回転で表示するアニメーションの有無
    animateRotate : true,
    // 中央から拡大しながら表示するアニメーションの有無
    animateScale : true,
    // アニメーション終了後に実行する処理
    // animation: false の時にも実行されるようです
    // e.g. onAnimationComplete : function() {alert('complete');}
    onAnimationComplete : null
};


window.addEventListener('load', function() {
  window.tabs = ["os", "browser", "comb"];
  window.pie = [];
  window.line = [];

  handleFileSelect = function(evt) {
    evt.stopPropagation();
    evt.preventDefault();
    var file = evt.dataTransfer.files[0];
    var reader = new FileReader();
    reader.onload = function(e) {
      var analytics = JSON.parse(reader.result);
      window.tabs.forEach(function(name){
        drawPie(analytics.pie, name);
        writeRanking(analytics.pie, name);
        drawLine(analytics.line, name);
      });
    };
    reader.readAsText(file);
  };

  handleDragOver = function(evt) {
    evt.stopPropagation();
    evt.preventDefault();
    evt.dataTransfer.dropEffect = 'copy';
  };

  var dropZone = document.getElementById('drop_zone');
  dropZone.addEventListener('dragover', handleDragOver,   false);
  dropZone.addEventListener('drop',     handleFileSelect, false);

  drawPie = function(pie, type) {
    var data  = pie[type];
    var other = {label:"other", access:0, color:"#607D8B"};
    data = data.filter(function(ele, i) {
      ele.color = COLORS[i % COLORS.length];
      if (ele.value < 0.5) {
        other.access += ele.access;
        return false;
      }
      return true;
    });
    other.value = Math.round(other.access * 10000.0 / pie.total) / 100;
    data.push(other);
    if (window.pie[type]) window.pie[type].clear();
    window.pie[type] = new Chart(document.getElementById(type + "_pie").getContext("2d")).Pie(data, options);
    pie[type] = data;
  };

  writeRanking = function(pie, type) {
    var data  = pie[type];
    var ul = document.getElementById(type + "_share_list");
    while (ul.firstChild) ul.removeChild(ul.firstChild);
    data.forEach(function(ele){
      var li = document.createElement("li");
      li.innerHTML = ele.label + " : " + ele.value + "% (" + ele.access + " Access)";
      li.style.color = ele.color;
      ul.appendChild(li);
    });
  };

  drawLine = function(line, type) {
    data = line[type];
    data.datasets = data.datasets.filter(function(ele, i) {
      ele.fillColor = "rgba(96, 125, 139, 0)";
      ele.strokeColor = COLORS[i % COLORS.length];
      ele.pointColor = COLORS[i % COLORS.length];
      ele.pointStrokeColor = "#fff";
      ele.pointHighlightFill = "#fff";
      ele.pointHighlightStroke = COLORS[i % COLORS.length];
      var ave = ele.data.reduce(function(prev, current) {return prev+current;}) / ele.data.length;
      return ave >= 0.5;
    });
    if (window.line[type]) window.pie[type].clear();
    window.line[type] = new Chart(document.getElementById(type + "_line").getContext("2d")).Line(data);
  };

});
