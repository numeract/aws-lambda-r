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


# pure function (preferable), receives parameters and returns a json
aws_lambda_r <- function(request_id) {
    
    # generic default error message
    # defined only to illustrate how the function works
    output_json <- '{"message": "Cannot create output JSON"}'
    
    # possible implementation: catch all errors 
    tryCatch({
        # perform any operations you want
        # put the results in a list
        output_lst <- list(
            result_id = request_id,
            result_lst = list(a = 1, b = 2:4),
            result_dbl = 1:10 / 2,
            message = NULL
        )
        # wrap the results up in a json
        output_json <- to_json(output_lst)
        
    }, error = function(e) {
        output_json <<- paste0('{"message": "', e$message, '"}')
    })
    
    output_json
}

