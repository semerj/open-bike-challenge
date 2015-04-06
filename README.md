Bay Area Bike Share: D3 Chord Diagram Visualization
===================

SF Bay Area Bike Share data [visualization](http://semerj.github.io/open-bike-challenge) using D3 and sliders for filtering between year-month combinations.

The slider functionality is based on code from [Carson Farmer](http://bl.ocks.org/carsonfarmer/11478345). Colors are based on neighborhood and are ordered to appear near each other. 

Taking the cartesian product of the start and end stations for each year-month combination resulted in missing data for stations that (1) weren't online yet, or (2) didn't have any rides between them. These "missing" values where replaced with a very small value so that station labels would always appear in the chord diagram.

Data source: [Bay Area Bike Share](http://bayareabikeshare.com/datachallenge)
