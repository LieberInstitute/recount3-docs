library('rsconnect')
options(repos = BiocManager::repositories())
setwd(here::here("study-explorer"))
load('.deploy_info.Rdata')
rsconnect::setAccountInfo(name="jhubiostatistics", token=deploy_info$token,
    secret=deploy_info$secret)

deployApp(appFiles = c('ui.R', 'server.R', 'projects_meta.Rdata'),
    appName = 'recount3-study-explorer', account = "jhubiostatistics")
Y
