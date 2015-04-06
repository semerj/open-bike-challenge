/*
   Visualization based on:
   https://gist.github.com/carsonfarmer/11478345
   http://bl.ocks.org/carsonfarmer/11478345
*/

var data,
    matrices,
    stations,
    years;

var last_chord = {};

var formatPercent = d3.format(".1%");

var width = 1100,
    height = 1000,
    padding = 150,
    r0 = (Math.min(width, height)-padding * 2) * 0.41,
    r1 = r0 * 1.05;

var svg = d3.select("#chart").append("svg")
    .attr("width", width)
    .attr("height", height)
  .append("g")
    .attr("id", "circle")
    .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

svg.append("circle")
    .attr("r", r1);

// add slider functionality
d3.select("#slider").on('change', function(d) {
    var current = years[parseInt(this.value)],
        year = current.substring(0, 4),
        month = current.substring(5);

    d3.select("#month").text("" + month);
    d3.select("#year").text("" + year);

    var new_data = matrices[current];

    rerender(new_data);
});

d3.csv("rides.csv", function(rides) {
  d3.json("rides_ym.json", function(matrix) {
    matrices = matrix,
    years    = Object.keys(matrices).sort(),
    current  = years[0],
    stations = rides;

    d3.select("#slider")
      .attr("max", years.length-1);

    // Compute the chord layout.
    data = matrices[current];

    var chord = d3.layout.chord()
      .padding(0.02)
      .sortSubgroups(d3.descending)
      // .sortChords(d3.ascending)
      .matrix(data);

    // draw arcs
    svg.append("g")
       .selectAll("path")
       .data(chord.groups)
     .enter().append("path")
       .on("mouseover", mouseover)
       .attr("class", "arc")
       .style("fill", function(d, i) { return rides[i].color; })
       .style("stroke", function(d, i) { return rides[i].color; })
       .attr("d", d3.svg.arc().innerRadius(r0).outerRadius(r1))
       .append("title").text(function(d, i) {
         return stations[i].name + ": " + formatPercent(d.value) + " of origins";
       });

    // draw chords
    svg.append("g")
       .attr("class", "chord")
       .selectAll("path")
       .data(chord.chords)
     .enter().append("path")
       .attr("d", d3.svg.chord().radius(r0))
       .style("fill", function(d, i) { return rides[d.source.index].color; })
       .style("stroke", '#333')
       .attr("visibility", function(d, i) { return d.source.value > 0.000001 ? "visible" : "hidden"; })
       .style("opacity", 1)
       .append("title").text(function(d) {
        return stations[d.source.index].name
          + " → " + stations[d.target.index].name
          + ": " + formatPercent(d.source.value)
          + "\n" + stations[d.target.index].name
          + " → " + stations[d.source.index].name
          + ": " + formatPercent(d.target.value);
        });


    var ticks = svg.append("g")
        .attr("class", "ticks")
        .selectAll("g")
        .data(chord.groups)
        .enter().append("g")
          .on("mouseover", mouseover)
          .attr("class", "group")
        .selectAll("g")
        .data(groupTicks)
        .enter().append("g")
        .attr("class", "stations")
        .attr("transform", function(d) {
          return "rotate(" + (d.angle * 180 / Math.PI - 90) + ")"
              + "translate(" + r1 + ",0)";
        });


    ticks.append("text")
         .attr("x", 8)
         .attr("dy", '.35em')
         .attr("text-anchor", function(d) {
               return d.angle > Math.PI ? "end" : null;
             })
         .attr("transform", function(d) {
               return d.angle > Math.PI ? "rotate(180)translate(-16)" : null;
             })
         .text(function(d) { return d.label; });

    last_chord = chord;

  });
});

function rerender(data) {

  var chord = d3.layout.chord()
    .padding(.02)
    .sortSubgroups(d3.descending)
    // .sortChords(d3.ascending)
    .matrix(data);

  // update ticks
  svg.selectAll(".ticks")
     .selectAll(".group")
     .data(chord.groups)
    .selectAll(".stations")
     .data(groupTicks)
     .transition()
     .duration(1500)
      .attr("transform", function(d) {
        return "rotate(" + (d.angle * 180 / Math.PI - 90) + ")"
            + "translate(" + r1 + ",0)";
      });

  // update arcs
  svg.selectAll(".arc")
     .data(chord.groups)
     .transition()
     .duration(1000)
     .attrTween("d", arcTween(last_chord))
     .select("title").text(function(d, i) {
         return stations[i].name + ": " + formatPercent(d.value) + " of origins";
       });

  // update chords
  svg.select(".chord")
     .selectAll("path")
     .data(chord.chords)
     .transition()
     .duration(1000)
     .attrTween("d", chordTween(last_chord))
     .select("title").text(function(d) {
        return stations[d.source.index].name
          + " → " + stations[d.target.index].name
          + ": " + formatPercent(d.source.value)
          + "\n" + stations[d.target.index].name
          + " → " + stations[d.source.index].name
          + ": " + formatPercent(d.target.value);
        });

  last_chord = chord;
}

var arc =  d3.svg.arc()
      .startAngle(function(d) { return d.startAngle; })
      .endAngle(function(d) { return d.endAngle; })
      .innerRadius(r0)
      .outerRadius(r1);

var chordl = d3.svg.chord().radius(r0);

function arcTween(chord) {
  return function(d,i) {
    var i = d3.interpolate(chord.groups()[i], d);

    return function(t) { return arc(i(t)); };
  }
}

function chordTween(chord) {
  return function(d,i) {
    var i = d3.interpolate(chord.chords()[i], d);

    return function(t) { return chordl(i(t)); };
  }
}

function groupTicks(d) {
  var k = (d.endAngle - d.startAngle) / d.value;
    return [{
      angle: d.value * k / 2 + d.startAngle,
      label: stations[d.index].name
    }];
}

function mouseover(d, i) {
  d3.selectAll(".chord path")
    .classed("fade", function(p) {
    return p.source.index != i
        && p.target.index != i;
  });
}
