library(jsonlite)


from_json <- function(json) {
    
    # basic exceptions
    if (length(json) == 0L || is.na(json) || nchar(json) == 2L) json <- '{}'
    
    jsonlite::fromJSON(json)
}


to_json <- function(lst) {
    
    jsonlite::toJSON(
        lst,
        dataframe = 'rows',
        null = 'list',
        na = 'null',
        auto_unbox = TRUE, 
        digits = NA,
        pretty = TRUE
    )
}


# pure function (preferable), receives a json and returns a json
aws_lambda_r <- function(input_json) {
    # generic default error message
    # defined only to illustrate how the function works
    output_json <- '{"message": "Cannot create output JSON"}'
    # possible implementation: catch all errors 
    encoded_picture <- "Default img"
    tryCatch({
        input_lst <- from_json(input_json)
        request_id <- input_lst$request_id[1]
        t <- tempfile()
        png(t,type = "cairo")
        options(device = "png")
        invisible(par())
        plot(rnorm(10))
        invisible(dev.off())
        encoded_picture <- base64enc::base64encode(t)
        unlink(t)
        
    }, error = function(e) {
        encoded_picture <- "Invalid base65"
    })
    encoded_picture
}

#x <- aws_lambda_r('{"request_id" : 1111}')
#str(x)
