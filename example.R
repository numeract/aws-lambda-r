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
  #  t <- tempfile()
  #  png(t,type = "cairo")
   # options(device = "png")
  #  invisible(par())
  #  plot(rnorm(10))
  #  invisible(dev.off())
 # ncoded_picture <- base64enc::base64encode(t)
  #  unlink(t)
    # possible implementation: catch all errors 
    img <- "Default img"
    tryCatch({
        input_lst <- from_json(input_json)
        request_id <- input_lst$request_id[1]
        output_lst <- list(
            result_id = request_id,
            result_lst = list(a = 1, b = 2:4),
            result_dbl = 1:10 / 2,
            message =  NULL
        )
        img <- "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"
        output_json <- to_json(output_lst)
        
    }, error = function(e) {
        output_json <<- paste0('{"message": "', e$message, '"}')
        img <- "Invalid base65"
    })
    img
}

#x <- aws_lambda_r('{"request_id" : 1111}')
#str(x)
