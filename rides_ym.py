import json
import pandas as pd

rides = pd.read_csv("./data/201402_trip_data.csv")
stations = pd.read_csv("./data/201402_station_data.csv")

# filter only san francisco stations
sf_stations = stations[stations.landmark == "San Francisco"].name.tolist()
sf = rides[(rides['Start Station'].isin(sf_stations)) & (rides['End Station'].isin(sf_stations))]

categories = ["Financial District", "Financial District",
              "Financial District", "Chinatown",
              "Financial District", "Embarcadero",
              "Embarcadero", "Embarcadero",
              "Embarcadero", "Union Square",
              "Embarcadero", "SOMA",
              "Financial District", "SOMA",
              "Civic Center", "Civic Center",
              "Embarcadero", "SOMA",
              "SOMA", "SOMA",
              "SOMA", "SOMA",
              "Civic Center", "Civic Center",
              "SOMA", "SOMA",
              "SOMA", "Union Square",
              "Civic Center", "Chinatown",
              "Embarcadero", "Financial District",
              "Union Square", "Financial District",
              "Financial District"]

color_grp = pd.DataFrame({"category": list(set(categories)),
                          "color": ["#d53e4f", "#fc8d59", "#fee08b",
                                    "#e6f598", "#99d594", "#3288bd"]})

grp = pd.DataFrame({"name": sf_stations,
                    "category": categories}).sort("category")

grp_merge = pd.merge(grp, color_grp, on="category")

# save station-color csv
grp_merge[["name", "color"]].to_csv("rides.csv", index=False)

# create json file
sf.loc[:,'Start Date'] = pd.to_datetime(sf['Start Date'], format="%m/%d/%Y %H:%M")
sf['YearMonth'] = sf['Start Date'].dt.year.astype('string') + "-" + sf['Start Date'].dt.month.map("{:02}".format).astype('string')

sf_counts = sf.groupby(['YearMonth', 'Start Station', 'End Station']).size().reset_index()
sf_counts.rename(columns={0:'Count'}, inplace=True)

sf_prop = sf_counts.copy()
sf_prop['Prop'] = sf_prop.groupby('YearMonth').Count.apply(lambda x: x/float(x.sum()))
sf_prop["Start Station"] = sf_prop["Start Station"].astype("category")
sf_prop["Start Station"] = sf_prop["Start Station"].cat.reorder_categories(grp.name)
sf_prop["End Station"] = sf_prop["End Station"].astype("category")
sf_prop["End Station"] = sf_prop["End Station"].cat.reorder_categories(grp.name)
sf_prop = sf_prop.sort(columns=["YearMonth", "Start Station", "End Station"])

sf_wide = pd.pivot_table(sf_prop, index=["YearMonth", "Start Station"], columns="End Station", values="Prop")

# fill in rides where there is no trips between stations
sf_wide = sf_wide.fillna(0.000001)

ym_index = ['2013-08', '2013-09', '2013-10', '2013-11', '2013-12', '2014-01', '2014-02']
station_index = grp.name.tolist()

# reindex pivot table
# import itertools
# sf_wide = sf_wide.reindex(index=list(itertools.product(ym_index, station_index)), columns=station_index)
ix = pd.MultiIndex.from_product([ym_index, station_index], names=['YearMonth', 'Station'])
sf_wide = sf_wide.reindex(ix)

with open("rides_ym.json", "w") as outfile:
    json_data = {ym: sf_wide[sf_wide.index.get_level_values(0) == ym].T.as_matrix().tolist() for ym in ym_index}
    json.dump(json_data, outfile)

