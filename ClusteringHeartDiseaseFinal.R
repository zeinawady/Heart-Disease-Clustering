# Install and load required libraries
install.packages(c("cluster", "tidyverse", "dbscan", "factoextra", "scales", "clusterCrit", "ggplot2"))

library(cluster)    # For silhouette function and clustering
library(tidyverse)  # For data manipulation
library(dbscan)     # For DBSCAN clustering
library(factoextra) # For cluster visualization
library(scales)     # For scaling numerical data
library(clusterCrit) # For Davies-Bouldin index
library(ggplot2)    # For data visualization

# Read Data
df <- read.csv("C:\\Users\\zeina\\OneDrive\\Documents\\Heartdiseas.csv")

# closer look on the data
print(head(df, 5))
print(tail(df, 5))
print(str(df))
print(dim(df))
print(names(df))

#------- Data Cleaning-------

df <- df[, -1]  # Drop ID column
print(head(df))


# Check for missing values 
print(colSums(is.na(df))) #number of nulls in each column

#clean null values
mode_slope <- as.numeric(names(sort(table(df$slope), decreasing = TRUE)[1])) #calculate the most common value 
#create a frequency table of each value 
#then sort them according to the frequency in descending order 
#then choose the value (names) in first index and returns it as numeric value
df$slope[is.na(df$slope)] <- mode_slope  # Replace NA in slope with calculated mode
print(colSums(is.na(df)))


# Check and remove duplicates
print(sum(duplicated(df)))
df <- df[!duplicated(df),] #include only the non duplicated data
print(sum(duplicated(df)))

# Extracting new feature -> Heart Rate Recovery 
df$hrr <- df$thalach - 70
print(head(df$hrr))

# Select relevant features in heart disease diagnosis
#trestbps (Resting Blood Pressure) , thalach (Maximum Heart Rate Achieved) , oldpeak (abnormal heart response during exercise)

selected_features <- df[, c("age", "trestbps", "chol", "thalach", "oldpeak", "hrr")]

#scale data -> (mean = 0, standard deviation = 1 and have similar range)
df_scaled <- scale(selected_features)



# -------K-Means Clustering------

#choose the best number of clusters 
wss <- numeric(10) #create empty numeric vector
for (c in 1:10) {
  km <- kmeans(df_scaled, centers = c, nstart = 25)
  wss[c] <- km$tot.withinss
}

# Plot elbow curve to determine optimal number of clusters
plot(1:10, wss, type = "b", xlab = "Number of Clusters", 
     ylab = "Within-cluster Sum of Squares", 
     main = "Elbow Method for Optimal k")

# Perform K-Means with k = 3 as shown in the graph
kmeans_result <- kmeans(df_scaled, centers = 3, nstart = 25)

#evaluate the quality of clustering
#measure how well each point fits in the assigned cluster 
silhouette_kmeans <- silhouette(kmeans_result$cluster, dist(df_scaled))
avg_silhouette_kmeans <- mean(silhouette_kmeans[, 3])
cat("K-Means Metrics:\n")
cat("Silhouette Score:", round(avg_silhouette_kmeans, 3), "\n")

#visualize kmeans
fviz_cluster(list(data = df_scaled, cluster = kmeans_result$cluster),
             geom = "point", ellipse.type = "norm",
             main = "K-Means Clustering")



# -------DBSCAN Clustering------

dbscan_result <- dbscan(df_scaled, eps = 0.8, minPts = 5)

valid_points <- dbscan_result$cluster != 0 #exclude cluster 0 which is noise 

#evaluate 
silhouette_dbscan <- silhouette(dbscan_result$cluster[valid_points], dist(df_scaled[valid_points, ]))
avg_silhouette_dbscan <- mean(silhouette_dbscan[, 3])
cat("DBSCAN Metrics:\n")
cat("Silhouette Score:", round(avg_silhouette_dbscan, 3), "\n")

#visualize
fviz_cluster(list(data = df_scaled, cluster = dbscan_result$cluster),
             geom = "point", ellipse.type = "convex",
             main = "DBSCAN Clustering")



#---------- Hierarchical Clustering----------

hc <- hclust(dist(df_scaled), method = "ward.D2")
hc_clusters <- cutree(hc, k = 3)

silhouette_hc <- silhouette(hc_clusters, dist(df_scaled))
avg_silhouette_hc <- mean(silhouette_hc[, 3])
cat("Hierarchical Metrics:\n")
cat("Silhouette Score:", round(avg_silhouette_hc, 3), "\n")

plot(hc, main = "Hierarchical Clustering", xlab = "", sub = "")
rect.hclust(hc, k = 3, border = "red")

fviz_cluster(list(data = df_scaled, cluster = hc_clusters),
             geom = "point", ellipse.type = "convex",
             main = "Hierarchical Clustering")


# --------------K-Medoids--------------
pam_result <- pam(df_scaled, k = 3)
silhouette_score <- silhouette(pam_result$clustering, dist(df_scaled))
avg_silhouette_score <- mean(silhouette_score[, 3])

cat("Average Silhouette Score:", round(avg_silhouette_score, 3), "\n")

#visualize
fviz_cluster(list(data = df_scaled, cluster = pam_result$clustering),
             geom = "point", ellipse.type = "norm",
             main = "K-Medoids Clustering")



#------------- Reduced Feature Clustering (Selects fewer and different columns for clustering)-------------

selected_features_reduced <- df[, c("age", "trestbps", "chol", "thalach", "hrr")]
df_scaled_reduced <- scale(selected_features_reduced)

kmeans_reduced <- kmeans(df_scaled_reduced, centers = 3, nstart = 25)
silhouette_kmeans_reduced <- silhouette(kmeans_reduced$cluster, dist(df_scaled_reduced))
avg_silhouette_kmeans_reduced <- mean(silhouette_kmeans_reduced[, 3])

cat("K-Means with Reduced Features:\n")
cat("Silhouette Score:", round(avg_silhouette_kmeans_reduced, 3), "\n")


#another trial by removing hrr and adding sex feature
selected_features_reduced_sec <- df[, c("age", "sex", "trestbps", "chol", "thalach", "oldpeak")]

df_scaled_reduced_sec <-scale(selected_features_reduced_sec)
kmeans_reduced2 <- kmeans(df_scaled_reduced_sec, centers = 3, nstart = 25)
silhouette_kmeans_reduced2 <- silhouette(kmeans_reduced2$cluster, dist(df_scaled_reduced_sec))
avg_silhouette_kmeans_reduced <- mean(silhouette_kmeans_reduced2[, 3])

cat("K-Means without hrr feature:\n")
cat("Silhouette Score:", round(avg_silhouette_kmeans_reduced, 3), "\n")


#another trial by removing hrr and adding restecg feature
selected_features_reduced_sec <- df[, c("age", "restecg", "trestbps", "chol", "thalach", "oldpeak")]

df_scaled_reduced_sec <-scale(selected_features_reduced_sec)
kmeans_reduced2 <- kmeans(df_scaled_reduced_sec, centers = 3, nstart = 25)
silhouette_kmeans_reduced2 <- silhouette(kmeans_reduced2$cluster, dist(df_scaled_reduced_sec))
avg_silhouette_kmeans_reduced <- mean(silhouette_kmeans_reduced2[, 3])

cat("K-Means without hrr feature:\n")
cat("Silhouette Score:", round(avg_silhouette_kmeans_reduced, 3), "\n")

