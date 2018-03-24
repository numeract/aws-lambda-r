# plumber demo main file

# examples from: https://www.rplumber.io/


library(plumber)


r <- plumber::plumb("docs/plumber_functions.R")

r$run(port = 8000)


# http://localhost:8000/mean
# http://localhost:8000/mean?samples=10000

# curl --data "a=4&b=3" "http://localhost:8000/sum"
