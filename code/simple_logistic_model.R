library(data.table)
# TODO: make duration function and wrap in a genFeatures function
speedDistribution <- function(trip)
{
    # Returns vector of 20 values: quantiles of average speed over 20s windows 
    # distance covered over every 20 second window (starting at 20th second)
    # 3.6 - convert to k/h from m/s
    vitesse = 3.6*sqrt(diff(trip$x,20,1)^2 + diff(trip$y,20,1)^2)/20
    return(quantile(vitesse, seq(0.05,1, by = 0.05)))
}

dropboxDir <- '~/Dropbox/UCL/UCLOL/Telematics/data/'
driverDir <- paste0(dropboxDir, 'input/drivers/')
submissionDir <- paste0(dropboxDir, 'output/')

set.seed(1234)
drivers = list.files(driverDir)
randomDrivers = sample(drivers, size = 5)

refData = NULL
target = 0
names(target) = "target"
for(driver in randomDrivers)
{
  dirPath = paste0(driverDir, driver, '/')
  for(i in 1:200)
  {
    trip = read.csv(paste0(dirPath, i, ".csv"))
#     trip = fread(paste0(dirPath, i, ".csv"))
    features = c(speedDistribution(trip), target)
    refData = rbind(refData, features)
  }
}

# TODO: use own labels?
target = 1
names(target) = "target"
submission = NULL
for(driver in drivers)
{
  print(driver)
  dirPath = paste0(driverDir, driver, '/')
  currentData = NULL
  for(i in 1:200)
  {
    trip = read.csv(paste0(dirPath, i, ".csv"))
#     trip = fread(paste0(dirPath, i, ".csv"))
    features = c(speedDistribution(trip), target)
    currentData = rbind(currentData, features)
  }
  train = rbind(currentData, refData)
  train = as.data.frame(train)
  g = glm(target ~ ., data=train, family = binomial("logit"))
  currentData = as.data.frame(currentData)
  p = predict(g, currentData, type = "response")
  labels = sapply(1:200, function(x) paste0(driver,'_', x))
  result = cbind(labels, p)
  submission = rbind(submission, result)
}

colnames(submission) = c("driver_trip","prob")
write.csv(submission, paste0(submissionDir, 'logistic__', Sys.time(), '.csv'), 
          row.names=F, quote=F)
save(submission, file = paste0(submissionDir, 'logistic__', Sys.time(), '.RData'))
