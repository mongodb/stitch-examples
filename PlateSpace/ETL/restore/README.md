# PlateSpace Sample Data

The purpose of this script is to load restaurant data (999 restaurants in Chicago) into a MongoDB Atlas database using `mongorestore`.

Getting Started:

  1. Clone/download repository
  1. Create a MongoDB Atlas cluster
  1. On the __Clusters__ page, press the __Metrics__ button under your cluster name and get the fully qualified domain name (FQDN) of your primary node (the primary node can easily be identified by a black P icon)
  1. Edit the _restore.sh_ file:
    - `PRIMARY="Primary Server:27017"`: here you need to put the FQDN of your MongoDB Atlas primary node.
    - `USERNAME`: enter your Atlas admin username (from the __MongoDB Users__ tab of your MongoDB Atlas cluster)
    - `PASSWORD`: enter you your Atlas admin password
  1. Run command `bash restore.sh`
