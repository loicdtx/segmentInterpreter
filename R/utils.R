# This function compute cloud information for a df row containing the inputs, B1, B3, B4, B7, NDSI, NDVI
# Use it as an input to mutate() following rowwise()
cloudShadow <- function(B1, B3, B4, B7, NDSI, NDVI) {
  cloud1 <- FALSE #ifelse(B7 > 300 & NDSI < 0.8 & NDVI < 0.8, TRUE, FALSE) # Should be done only when B6 is available
  cloud2 <- ifelse((B1 - 0.5 * B3 - 800) > 0, TRUE, FALSE)
  # If at least one of the two cloud tests is positive, then say it's a cloud
  cloudCombined <- ifelse(cloud1 | cloud2, TRUE, FALSE)
  shadow <- ifelse(B4 < 1500, TRUE, FALSE)
  if(cloudCombined & !shadow) {
    out <- 'cloud'
  } else if(!cloudCombined & shadow) {
    out <- 'shadow'
  } else if (cloudCombined & shadow) {
    out <- 'weird'
  } else {
    out <- 'land'
  }
  return(out)
}

#' Parse landsat ID with regular expression and returns the date of acquisition
#' 
#' @param id character or vector of characters. The Landsat scene name(s)
#' 
#' @return Date or vector of dates
#' 
#' @import stringr
#' 
#' @examples 
#' getLandsatDate('LT50050572010017')
#' ## With a vector of scene names
#' getLandsatDate(c('LT50050572010017', 'LT52320572010343'))

getLandsatDate <- function(id) {
  cleanID <- str_extract(id, '(LT4|LT5|LE7|LC8)\\d{13}') 
  dates <- as.Date(substr(cleanID, 10, 16), format="%Y%j")
  return(dates)
}

