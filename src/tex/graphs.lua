--- Graphs
-- @module Graphs

Graphs = {}

local function intervalToString (interval, axis)
  local line = ""
  if interval.from then line = string.format("%s%smin=%.4f, ", line, axis, interval.from) end
  if interval.to then line = string.format("%s%smax=%.4f, ", line, axis, interval.to) end
  return line
end

local function intervalDiff(interval)
  return interval.to - interval.from
end

local function mergeAndUpdateInterval(a,b)

  local r = {
    from = b.from or a.from,
    to = b.to or a.to
  }

  local buffer = intervalDiff(r) * 0.1

  if not b.from then r.from = r.from - buffer end
  if not b.to then r.to = r.to + buffer end

  return r
end

---
-- @int[opt] from lower bound
-- @int[opt] to upper bound
-- @table Interval

---
-- Boundaries
-- @tparam Interval x
-- @tparam Interval y
-- @table Boundaries

---
-- @string label label of axis
-- @tparam Interval interval for axis
-- @table Axis

---
-- @tparam Axis x x-axis
-- @tparam Axis y left y-axis
-- @tparam[opt] Axis y2 right y-axis
-- @tparam Boundaries boundaries of figure
-- @tparam Boundaries boundaries2 of figure
-- @string caption caption of figure
-- @string fig label of figure
-- @table GraphOptions

---
-- @string[opt] label label for plot
-- @string[opt] color color for plot
-- @string[opt] style style for plot
-- @string[opt] marker marker for plot
-- @string file name of file
-- @string columns columns for x- and y-axis in file
-- @table PlotOptions

---
-- create tex code for line graph with one or two axis
--
-- @tparam GraphOptions graphOptions graph options
-- @tparam [PlotOptions] plotOptions list of plot options
--
-- @treturn string tex code for line graph
--
Graphs.lineGraph = function (graphOptions, plotOptions)

  graphOptions.x.interval = mergeAndUpdateInterval(graphOptions.boundaries.x, graphOptions.x.interval)
  graphOptions.y.interval = mergeAndUpdateInterval(graphOptions.boundaries.y, graphOptions.y.interval)

  local legendentries = ""
  if #plotOptions > 1 then
      legendentries = {}
      for _,plotOption in pairs(plotOptions) do

          table.insert(legendentries, table.concat({[[
    \addlegendentry{]], plotOption.label, [[}
          ]]}))
      end

      legendentries = table.concat(legendentries)
  end

  local plots = {}
  for _,plotOption in pairs(plotOptions) do

    table.insert(plots, table.concat({[[
    \addplot [color=]], plotOption.color or "red", ", style=", plotOption.style or "solid", ", mark=", plotOption.marker or "*", "] table [", plotOption.columns, ", col sep=comma] {", plotOption.file, [[};
    ]]}))

  end
  plots = table.concat(plots)

  local secondAxis = ""
  if graphOptions.y2 then

      graphOptions.y2.interval = mergeAndUpdateInterval(graphOptions.boundaries2.y, graphOptions.y2.interval)

      secondAxis = table.concat({[[
  \begin{axis}[
    axis y line=right, axis x line=none, ]], intervalToString(graphOptions.y2.interval, "y"), [[

    ylabel={]], graphOptions.y2.label, [[},
    y label style={at={(1.02,0.5)}},
    every y tick scale label/.style={ at={(1,1.075)},anchor=north west}
  ]

  \addplot[no marks] coordinates {(1,]], graphOptions.y2.interval.to, [[)};

  \end{axis}

  ]]})

  end

  return table.concat({[[
\pgfplotsset {
  width=0.9\textwidth, height=0.45\textwidth,
  axis x line=bottom, ]], intervalToString(graphOptions.x.interval, "x"), [[

  grid style={semithick, densely dotted}
}

\begin{tikzpicture}
  \begin{axis}[
    axis y line=left, ]], intervalToString(graphOptions.y.interval, "y"), [[

    grid=major,
    xlabel={]], graphOptions.x.label, [[},
    ylabel={]], graphOptions.y.label, [[},
    legend columns=]], #plotOptions, [[,
    legend style={at={(0.5,1.1)},anchor=north},
    y label style={at={(-0.02,0.5)}}
  ]
    ]], legendentries, [[

    ]], plots, [[

  \end{axis}

  ]], secondAxis, [[
\end{tikzpicture}
\caption{]], graphOptions.caption, [[}
\label{fig:]], graphOptions.fig, [[}
  ]]})
end


---
-- create tex code for line graph with one or two axis of stats
--
-- @tparam GraphOptions graphOptions graph options
-- @tparam file name of stats file
--
-- @treturn string tex code for line graph
--
Graphs.lineGraphForStats = function (graphOptions, file)

  local plotOptions = {
    { label="min",        color="gray", style="dashed", marker="x",       columns="x=parameter, y=min",  file=file },
    { label="$Q_{0.25}$", color="gray",                 marker="*",       columns="x=parameter, y=low",  file=file },
    { label="$Q_{0.75}$", color="gray",                 marker="*",       columns="x=parameter, y=high", file=file },
    { label="max",        color="gray", style="dashed", marker="x",       columns="x=parameter, y=max",  file=file },
    { label="$Q_{0.50}$", color="blue",                 marker="square*", columns="x=parameter, y=med",  file=file }
  }

  return Graphs.lineGraph(graphOptions, plotOptions)
end


Graphs.pointGraph = function (graphOptions, plotOptions)

  graphOptions.x.interval = mergeAndUpdateInterval(graphOptions.boundaries.x, graphOptions.x.interval)
  graphOptions.y.interval = mergeAndUpdateInterval(graphOptions.boundaries.y, graphOptions.y.interval)

  return table.concat({[[
\pgfplotsset {
  width=0.9\textwidth, height=0.45\textwidth,
  axis x line=bottom,
  grid style={semithick, densely dotted}
}

\pgfplotstableread[col sep=comma]{]], plotOptions.file, [[}\datatable

\begin{tikzpicture}
  \begin{axis}[
    axis y line=left,
    grid=major, ]], intervalToString(graphOptions.y.interval, "y"), [[

    xlabel={]], graphOptions.x.label, [[},
    ylabel={]], graphOptions.y.label, [[},
    y label style={at={(-0.02,0.5)}},
    xtick=data,% crucial line for the xticklabels directive
    xticklabels from table={\datatable}{parameter},
    ybar, enlarge x limits=0.05
  ]

  \addplot [fill=red, mark=*] table [ x expr=\coordindex, ]], plotOptions.columns, [[ ] {\datatable};

  \end{axis}
\end{tikzpicture}
\caption{]], graphOptions.caption, [[}
\label{fig:]], graphOptions.fig, [[}
  ]]})
end


---
-- @tparam Axis x x-axis
-- @tparam Axis y left y-axis
-- @tparam[opt] Axis y2 right y-axis
-- @tparam Boundaries boundaries of figure
-- @tparam Boundaries boundaries2 of figure
-- @string caption caption of figure
-- @string fig label of figure
-- @table GraphOptions

---
-- @string[opt] label label for plot
-- @string[opt] color color for plot
-- @string[opt] style style for plot
-- @string[opt] marker marker for plot
-- @string file name of file
-- @string columns columns for x- and y-axis in file
-- @string count number of items in file
-- @table PlotOptions

---
-- create tex code for box graph with one or two axis
--
-- @tparam GraphOptions graphOptions graph options
-- @tparam PlotOptions plotOptions plot options
--
-- @treturn string tex code for line graph
--
Graphs.boxGraphForStats = function (graphOptions, plotOptions)

  local ticks, plots = {}, {}
  for i=1,plotOptions.count do
    table.insert(ticks, tostring(i))
    table.insert(plots, TexBlocks.boxplotPlot(i-1))
  end
  ticks = table.concat(ticks, ",")
  plots = table.concat(plots)

  graphOptions.y.interval = mergeAndUpdateInterval(graphOptions.boundaries.y, graphOptions.y.interval)

  local secondAxis = ""
  if graphOptions.y2 then

    graphOptions.y2.interval = mergeAndUpdateInterval(graphOptions.boundaries2.y, graphOptions.y2.interval)

    secondAxis = table.concat({[[
  \begin{axis}[
    axis y line=right, axis x line=none, ]], intervalToString(graphOptions.y2.interval, "y"), [[

    xtick={1},
    xticklabels from table={\datatable}{parameter},
    ylabel={]], graphOptions.y2.label, [[},
    y label style={at={(1.02,0.5)}},
    every y tick scale label/.style={ at={(1,1.075)},anchor=north west}
  ]

    \addplot[no marks] coordinates {(1,]], graphOptions.y2.interval.from, [[)};

  \end{axis}

  ]]})
  end

  return table.concat({[[
\begin{tikzpicture}

  \pgfplotsset {
    width=0.9\textwidth, height=0.45\textwidth,
    axis x line=bottom,
    grid style={semithick, densely dotted}
  }

  \pgfplotstableread[col sep=comma]{]], plotOptions.file, [[}\datatable

  \begin{axis}[
    axis y line=left,
    boxplot/draw direction=y,
    ]], intervalToString(graphOptions.y.interval, "y"), [[
    grid=major,
    xlabel={]], graphOptions.x.label, [[},
    ylabel={]], graphOptions.y.label, [[},
    xtick={]], ticks, [[},
    xticklabels from table={\datatable}{parameter},
    x tick label style={rotate=45,anchor=east},
    legend style={at={(1.02,0.5)},anchor=north,legend cell align=left},
    y label style={at={(-0.02,0.5)}},
    enlarge x limits=0.05
  ]
  ]], plots, [[
  \end{axis}

  ]], secondAxis, [[
\end{tikzpicture}
\caption{]], graphOptions.caption, [[}
\label{fig:]], graphOptions.fig, [[}
  ]]})
end

---
-- @string x label for x-axis
-- @string y label for y-axis
-- @string caption caption of figure
-- @string fig label of figure
-- @table GraphLabels

---
-- create tex code for histogram graph
--
-- @tparam GraphLabels labels
-- @string columns columns of graph
-- @string range range of graph
-- @string file name of filecontent for data
--
-- @treturn string
--
Graphs.Histogram = function (labels, columns, range, file, func)
  return [[
  \begin{tikzpicture}
    \begin{axis}[
        axis x line=bottom, axis y line=left,
        width=0.9\textwidth, height=0.45\textwidth,
        grid=major,
        xlabel={]] .. labels.x .. [[},
        ylabel={]] .. labels.y .. [[},
        ]] .. range .. [[
      ]

        \addplot +[ycomb, mark=none] table []] .. columns .. [[, col sep=comma] {]] .. file .. [[};]] ..
--  TODO: Check     \addplot +[red, smooth, mark=none] {]] .. func .. [[};
[[    \end{axis}
  \end{tikzpicture}
  \caption{]] .. labels.caption .. [[}
  \label{fig:]] ..labels.fig .. [[}
  ]]
end

Graphs.Throughput = function (labels, columns, file, border)
  return [[
      \begin{tikzpicture}
          \begin{axis}[
              width=0.9\textwidth, height=0.45\textwidth,
              grid=major,
              xlabel={]] .. labels.x .. [[},
              ylabel={]] .. labels.y .. [[},
              xmin=0,xmax=100, ymin=0
          ]

              \addplot +[mark=none] table []] .. columns .. [[, col sep=comma] {]] .. file .. [[};
              \addplot +[mark=none] coordinates {(]] .. border .. [[, 0) (]] .. border .. [[, 100)};

          \end{axis}
      \end{tikzpicture}
      \caption{]] .. labels.caption .. [[}
      \label{fig:]] .. labels.fig .. [[}
  ]]
end