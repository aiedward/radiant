################################################################################
# functions to set initial values and take information from r_state
# when available
################################################################################

ip <- ifelse(running_local, "", session$request$REMOTE_ADDR)

# observe({
#   qs <- parseQueryString(session$clientData$url_search)
#   if(!is.null(qs$id) && qs$id != "")
#     ip <<- qs$id
# })

init_state <- function(r_data) {

  # initial plot height and width
  r_data$plotHeight <- 600
  r_data$plotWidth <- 600

  # Datasets can change over time (i.e. the changedata function). Therefore,
  # the data need to be a reactive value so the other reactive functions
  # and outputs that depend on these datasets will know when they are changed.
  robj <- load("../base/data/data_init/diamonds.rda")
  df <- get(robj)
  r_data[["diamonds"]] <- df
  r_data[["diamonds_descr"]] <- attr(df,'description')
  r_data$datasetlist <- c("diamonds")
  r_data
}

ip_inputs <- paste0("RadiantInputs",ip)
ip_data <- paste0("RadiantValues",ip)
ip_dump <- paste0("RadiantDumpTime",ip)

#### test section
# rm(list = ls())
# library(lubridate)
# library(dplyr)
# t1 <- lubridate::now()
# less_1 <- t1 - 5
# less_2 <- t1 - minutes(1)
# more_2 <- t1 - minutes(5)

# ip <- "127.0.0.1"
# ip_dump <- paste0("RadiantDumpTime",ip)
# assign(ip_dump, less_2)

# ip <- "127.0.0.2"
# ip_dump2 <- paste0("RadiantDumpTime",ip)
# assign(ip_dump2, more_2)

## email may work only on linux
# check_state_dump_times()
#### end test section

state_email <- function(body, subject = paste0("From: ", Sys.info()['nodename'])) {
  if(!require(sendmailR))
    install.packages("sendmailR", repos = "http://cran.rstudio.com")
  library(sendmailR)

  from <- '<vincent.nijs@gmail.com>'
  to <- '<vincent.nijs@gmail.com>'
  body <- paste0(body,collapse="\n")
  sendmail(from, to, subject, body,
           control=list(smtpServer='ASPMX.L.GOOGLE.COM'))
}

check_state_dump_times <- function() {

  dump_times <- ls(pattern = "^RadiantDumpTime", envir = .GlobalEnv)
  for (i in dump_times) {
    dump_time <- difftime(now(), get(i, envir=.GlobalEnv), units = "mins")
    body_part1 <- c("Before:\n",ls(pattern="^Radiant" ,envir = .GlobalEnv))
    if (dump_time > 1) {
      sub("RadiantDumpTime","",i) %>%
        paste0(c("RadiantInputs","RadiantValues","RadiantDumpTime"),.) %>%
        rm(list = ., envir = .GlobalEnv)
      body_part2 <- c("\n\nAfter:\n",ls(pattern="^Radiant" ,envir = .GlobalEnv))
      state_email(c(body_part1,body_part2))
    } else {
      state_email(c(body_part1, "\n\nDump times:\n",
                    dump_times,dump_time, "\n\nFull ls():\n",
                    ls(envir = .GlobalEnv)))
    }
  }
}

if(!running_local) {
  # are there any state files dumped more than 3 minutes ago?
  check_state_dump_times()
}

# load previous state if available
if (exists("r_state") && exists("r_data")) {
  r_data <- do.call(reactiveValues, r_data)
  r_state <- r_state
  rm(r_data, r_state, envir = .GlobalEnv)
} else if (exists(ip_inputs) && exists(ip_data)) {
  r_data <- do.call(reactiveValues, get(ip_data))
  r_state <- get(ip_inputs)
  rm(list = c(ip_inputs, ip_data, ip_dump), envir = .GlobalEnv)
} else {
  r_state <- list()
  r_data <- init_state(reactiveValues())
}

if(running_local) {
  # reference to radiant environment that can be accessed by exported functions
  r_env <<- pryr::where("r_data")
}

observe({
  # reset r_state on dataset change
  if(is.null(r_state$dataset) || is.null(input$dataset)) return()
  if(r_state$dataset != input$dataset) r_state <<- list()
})