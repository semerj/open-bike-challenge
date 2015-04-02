import pandas as pd


rides = pd.read_csv("./data/201402_trip_data.csv")
stations = pd.read_csv("./data/201402_station_data.csv")

# filter only san francisco stations
sf_stations = stations[stations.landmark == "San Francisco"].name.tolist()
sf = rides[(rides['Start Station'].isin(sf_stations)) & (rides['End Station'].isin(sf_stations))]

# manually categorize stations by neighborhood
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

# aggregate ride data
sf_counts = sf.groupby(['Start Station', 'End Station']).size().reset_index()
sf_counts.rename(columns={0:'Count'}, inplace=True)
sf_sum = sf_counts['Count'].sum()
sf_counts['Count'] = sf_counts['Count']/sf_sum

sf_counts["Start Station"] = sf_counts["Start Station"].astype("category")
sf_counts["Start Station"] = sf_counts["Start Station"].cat.reorder_categories(grp.name)

sf_counts["End Station"] = sf_counts["End Station"].astype("category")
sf_counts["End Station"] = sf_counts["End Station"].cat.reorder_categories(grp.name)

sf_counts = sf_counts.sort(columns=["Start Station", "End Station"])

# convert count data to wide
sf_wide = sf_counts.pivot(index="Start Station", columns="End Station", values="Count")
sf_wide = sf_wide.fillna(0)

# save as json
sf_wide.to_json("rides.json", orient="values")
