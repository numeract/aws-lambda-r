# plumber demo functions file

# examples from: https://www.rplumber.io/


#* @get /mean
normalMean <- function(samples = 10) {
    data <- rnorm(samples)
    mean(data)
}


#* @post /sum
addTwo <- function(a, b) {
    as.numeric(a) + as.numeric(b)
}


#' @get /plot
#' @png
function(){
    myData <- iris
    plot(myData$Sepal.Length, myData$Petal.Length,
         main = "All Species", xlab = "Sepal Length", ylab = "Petal Length")
}


users <- data.frame(
    uid = c(12,13),
    username = c("kim", "john")
)

#' @get /users/<id>
function(id) {
    subset(users, uid == id)
}
