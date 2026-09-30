/* global Core */
(function (TargetNS) {
    'use strict';
    TargetNS.Init = function () {
        var all = document.getElementById('StatsAll'), boxes = document.querySelectorAll('.StatsOrigin');
        if (all) all.addEventListener('change', function () { boxes.forEach(function (box) { box.checked = all.checked; }); });
        var holder = document.getElementById('TicketStatsChart');
        if (!holder) return;
        var data = JSON.parse(holder.getAttribute('data-chart')), max = Math.max.apply(null, data.Created.concat(data.Closed).concat([1]));
        var controls = document.createElement('div'); controls.className = 'TicketStatsSeries';
        Object.keys(data.Sources).forEach(function (origin) {
            var label = document.createElement('label'), box = document.createElement('input'); box.type = 'checkbox'; box.value = origin;
            box.addEventListener('change', function () { holder.querySelectorAll('[data-origin="' + origin + '"]').forEach(function (row) { row.hidden = !box.checked; }); });
            label.appendChild(box); label.appendChild(document.createTextNode(' ' + origin)); controls.appendChild(label);
        }); holder.appendChild(controls);
        var table = document.createElement('table'); table.className = 'DataTable TicketStatsChartFallback';
        table.innerHTML = '<thead><tr><th>Zeit</th><th>Erstellt</th><th>Geschlossen</th></tr></thead>';
        var body = document.createElement('tbody');
        data.Labels.forEach(function (label, index) { var row = document.createElement('tr'); row.innerHTML = '<td></td><td></td><td></td>'; row.cells[0].textContent = label; row.cells[1].textContent = data.Created[index]; row.cells[2].textContent = data.Closed[index]; row.cells[1].style.backgroundImage = 'linear-gradient(90deg,#5b8def ' + (100 * data.Created[index] / max) + '%,transparent 0)'; row.cells[2].style.backgroundImage = 'linear-gradient(90deg,#57a773 ' + (100 * data.Closed[index] / max) + '%,transparent 0)'; body.appendChild(row); });
        Object.keys(data.Sources).forEach(function (origin) { data.Labels.forEach(function (label, index) { var row = document.createElement('tr'); row.hidden = true; row.setAttribute('data-origin', origin); row.innerHTML = '<td></td><td></td><td></td>'; row.cells[0].textContent = label + ' – ' + origin; row.cells[1].textContent = data.Sources[origin].Created[index]; row.cells[2].textContent = data.Sources[origin].Closed[index]; body.appendChild(row); }); });
        table.appendChild(body); holder.appendChild(table);
    };
    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');
}(Core.Agent.TicketStatistics = Core.Agent.TicketStatistics || {}));
